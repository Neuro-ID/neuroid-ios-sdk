//
//  NIDCallStatusObserverServiceTests.swift
//  NeuroID
//

import CallKit
import Testing
@testable import NeuroID

// Lightweight mock conforming to CallProperties (CXCall cannot be instantiated in tests)
struct MockCallProperties: CallProperties {
    var hasEnded: Bool = false
    var isOnHold: Bool = false
    var hasConnected: Bool = false
    var isOutgoing: Bool = false
}

@Suite
struct NIDCallStatusObserverServiceTests {

    var eventStorageService: MockEventStorageService
    var configService: MockConfigService
    var service: NIDCallStatusObserverService

    init() {
        eventStorageService = MockEventStorageService()
        configService = MockConfigService()
        service = NIDCallStatusObserverService(
            eventStorageService: eventStorageService,
            configService: configService
        )
    }

    // MARK: - Duration

    @Test
    func ended_withoutPriorConnect_durationIsZero() {
        // End without a preceding connect — callStartTime was never set
        service.handleCallChange(hasEnded: true, isOnHold: false, hasConnected: false, isOutgoing: false)

        let event = eventStorageService.mockEventStore.last
        let durationAttr = event?.attrs?.first(where: { $0.n == "duration_ms" })
        #expect(durationAttr?.v == "0")
    }

    @Test
    func ended_afterConnect_durationIsPositive() {
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: true)
        service.handleCallChange(hasEnded: true, isOnHold: false, hasConnected: false, isOutgoing: true)

        let event = eventStorageService.mockEventStore.last
        let durationAttr = event?.attrs?.first(where: { $0.n == "duration_ms" })
        let duration = Int64(durationAttr?.v ?? "-1")
        #expect((duration ?? -1) >= 0, "Duration should be non-negative")
    }

    @Test
    func ended_callStartTimeIsResetAfterEnd() {
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: true)
        service.handleCallChange(hasEnded: true, isOnHold: false, hasConnected: false, isOutgoing: true)

        // Start a new call — callStartTime should be 0 so it gets set again
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: true)
        service.handleCallChange(hasEnded: true, isOnHold: false, hasConnected: false, isOutgoing: true)

        let event = eventStorageService.mockEventStore.last
        let durationAttr = event?.attrs?.first(where: { $0.n == "duration_ms" })
        let duration = Int64(durationAttr?.v ?? "-1")
        #expect((duration ?? -1) >= 0, "Second call duration should also be non-negative")
    }

    @Test
    func connected_callStartTimeOnlySetOnFirstConnect() {
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: true)
        let startTime = service.callStartTime

        // Simulate duplicate connect event (e.g. held then reconnected without end)
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: true)

        #expect(service.callStartTime == startTime, "callStartTime should not be overwritten by duplicate connect events")
    }

    // MARK: - Backward compatibility: existing "type" attr still present

    @Test
    func answered_outgoingCall_typeAttrPreserved() {
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: true)

        let event = eventStorageService.mockEventStore.last
        let typeAttr = event?.attrs?.first(where: { $0.n == "type" })
        #expect(typeAttr?.v == "outgoing")
    }

    @Test
    func answered_incomingCall_typeAttrPreserved() {
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: false)

        let event = eventStorageService.mockEventStore.last
        let typeAttr = event?.attrs?.first(where: { $0.n == "type" })
        #expect(typeAttr?.v == "incoming")
    }

    // MARK: - Progress values

    @Test
    func ringing_progressIsRinging() {
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: false, isOutgoing: false)

        let event = eventStorageService.mockEventStore.last
        let progressAttr = event?.attrs?.first(where: { $0.n == "progress" })
        #expect(progressAttr?.v == "ringing")
    }

    @Test
    func answered_progressIsAnswered() {
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: false)

        let event = eventStorageService.mockEventStore.last
        let progressAttr = event?.attrs?.first(where: { $0.n == "progress" })
        #expect(progressAttr?.v == "answered")
    }

    @Test
    func ended_progressIsEnded() {
        service.handleCallChange(hasEnded: true, isOnHold: false, hasConnected: false, isOutgoing: false)

        let event = eventStorageService.mockEventStore.last
        let progressAttr = event?.attrs?.first(where: { $0.n == "progress" })
        #expect(progressAttr?.v == "ended")
    }

    @Test
    func onHold_progressIsOnhold() {
        service.handleCallChange(hasEnded: false, isOnHold: true, hasConnected: false, isOutgoing: false)

        let event = eventStorageService.mockEventStore.last
        let progressAttr = event?.attrs?.first(where: { $0.n == "progress" })
        #expect(progressAttr?.v == "onhold")
    }

    // MARK: - startListeningToCallStatus

    @Test
    func startListening_whenAlreadyRegistered_doesNotReRegister() {
        // After init, service is already registered
        // Calling start again should be a no-op (no crash, no duplicate registration)
        service.startListeningToCallStatus()

        // Verify service still works correctly after no-op start
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: true)
        #expect(eventStorageService.mockEventStore.count == 1)
    }

    @Test
    func startListening_whenNotRegistered_andConfigEnabled_registers() {
        // Unregister first
        service.stopListeningToCallStatus()

        // Enable callInProgress in config
        configService.mockConfigCache.callInProgress = true

        // Now start listening — should register
        service.startListeningToCallStatus()

        // Verify service processes events (delegate is set)
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: false)
        let event = eventStorageService.mockEventStore.last
        #expect(event?.cp == CallInProgress.ACTIVE.rawValue)
    }

    @Test
    func startListening_whenNotRegistered_andConfigDisabled_doesNotRegister() {
        // Unregister first
        service.stopListeningToCallStatus()

        // Disable callInProgress in config
        configService.mockConfigCache.callInProgress = false

        // Attempt to start listening — should NOT register because config disables it
        service.startListeningToCallStatus()

        // Calling stop again should be a no-op (still not registered)
        service.stopListeningToCallStatus()

        // Service still works for direct handleCallChange calls
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: true)
        #expect(eventStorageService.mockEventStore.count == 1)
    }

    // MARK: - stopListeningToCallStatus

    @Test
    func stopListening_whenRegistered_unregisters() {
        // Service is registered after init
        service.stopListeningToCallStatus()

        // Verify we can re-register after stopping
        configService.mockConfigCache.callInProgress = true
        service.startListeningToCallStatus()

        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: false)
        #expect(eventStorageService.mockEventStore.count == 1)
    }

    @Test
    func stopListening_whenNotRegistered_isNoOp() {
        // Unregister
        service.stopListeningToCallStatus()

        // Calling stop again should not crash (no-op)
        service.stopListeningToCallStatus()

        // Service handleCallChange still works (it's independent of delegate registration)
        service.handleCallChange(hasEnded: true, isOnHold: false, hasConnected: false, isOutgoing: false)
        let event = eventStorageService.mockEventStore.last
        #expect(event?.cp == CallInProgress.INACTIVE.rawValue)
    }

    // MARK: - callObserver delegate (via processCall)

    @Test
    func callObserver_delegateMethod_outgoingConnectedCall() {
        let mockCall = MockCallProperties(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: true)

        service.processCall(mockCall)

        let event = eventStorageService.mockEventStore.last
        #expect(event?.cp == CallInProgress.ACTIVE.rawValue)
        let typeAttr = event?.attrs?.first(where: { $0.n == "type" })
        #expect(typeAttr?.v == "outgoing")
        let progressAttr = event?.attrs?.first(where: { $0.n == "progress" })
        #expect(progressAttr?.v == "answered")
    }

    @Test
    func callObserver_delegateMethod_incomingEndedCall() {
        let mockCall = MockCallProperties(hasEnded: true, isOnHold: false, hasConnected: false, isOutgoing: false)

        service.processCall(mockCall)

        let event = eventStorageService.mockEventStore.last
        #expect(event?.cp == CallInProgress.INACTIVE.rawValue)
        let typeAttr = event?.attrs?.first(where: { $0.n == "type" })
        #expect(typeAttr?.v == "incoming")
        let progressAttr = event?.attrs?.first(where: { $0.n == "progress" })
        #expect(progressAttr?.v == "ended")
    }

    @Test
    func callObserver_delegateMethod_onHoldCall() {
        let mockCall = MockCallProperties(hasEnded: false, isOnHold: true, hasConnected: false, isOutgoing: true)

        service.processCall(mockCall)

        let event = eventStorageService.mockEventStore.last
        #expect(event?.cp == CallInProgress.ACTIVE.rawValue)
        let progressAttr = event?.attrs?.first(where: { $0.n == "progress" })
        #expect(progressAttr?.v == "onhold")
    }

    @Test
    func callObserver_delegateMethod_ringingCall() {
        let mockCall = MockCallProperties(hasEnded: false, isOnHold: false, hasConnected: false, isOutgoing: false)

        service.processCall(mockCall)

        let event = eventStorageService.mockEventStore.last
        #expect(event?.cp == CallInProgress.INACTIVE.rawValue)
        let progressAttr = event?.attrs?.first(where: { $0.n == "progress" })
        #expect(progressAttr?.v == "ringing")
        let typeAttr = event?.attrs?.first(where: { $0.n == "type" })
        #expect(typeAttr?.v == "incoming")
    }

    @Test
    func callObserver_delegateIsSetAfterInit() {
        // After init, the delegate should be set — verify by stopping and restarting
        // This exercises the callObserver registration path
        service.stopListeningToCallStatus()
        configService.mockConfigCache.callInProgress = true
        service.startListeningToCallStatus()

        // The service should still be able to handle call changes
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: false, isOutgoing: true)
        let event = eventStorageService.mockEventStore.last
        let progressAttr = event?.attrs?.first(where: { $0.n == "progress" })
        #expect(progressAttr?.v == "ringing")
        let typeAttr = event?.attrs?.first(where: { $0.n == "type" })
        #expect(typeAttr?.v == "outgoing")
    }

    @Test
    func callObserver_fullLifecycle_incomingCall() {
        // Simulate full lifecycle: ringing -> answered -> on hold -> answered -> ended
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: false, isOutgoing: false)
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: false)
        service.handleCallChange(hasEnded: false, isOnHold: true, hasConnected: false, isOutgoing: false)
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: false)
        service.handleCallChange(hasEnded: true, isOnHold: false, hasConnected: false, isOutgoing: false)

        #expect(eventStorageService.mockEventStore.count == 5)

        // Verify final event is ended
        let lastEvent = eventStorageService.mockEventStore.last
        #expect(lastEvent?.cp == CallInProgress.INACTIVE.rawValue)
        let progressAttr = lastEvent?.attrs?.first(where: { $0.n == "progress" })
        #expect(progressAttr?.v == "ended")
    }

    // MARK: - cp (callInProgress status) values

    @Test
    func ringing_cpIsInactive() {
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: false, isOutgoing: false)

        let event = eventStorageService.mockEventStore.last
        #expect(event?.cp == CallInProgress.INACTIVE.rawValue)
    }

    @Test
    func answered_cpIsActive() {
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: false)

        let event = eventStorageService.mockEventStore.last
        #expect(event?.cp == CallInProgress.ACTIVE.rawValue)
    }

    @Test
    func onHold_cpIsActive() {
        service.handleCallChange(hasEnded: false, isOnHold: true, hasConnected: false, isOutgoing: false)

        let event = eventStorageService.mockEventStore.last
        #expect(event?.cp == CallInProgress.ACTIVE.rawValue)
    }

    @Test
    func ended_cpIsInactive() {
        service.handleCallChange(hasEnded: true, isOnHold: false, hasConnected: false, isOutgoing: false)

        let event = eventStorageService.mockEventStore.last
        #expect(event?.cp == CallInProgress.INACTIVE.rawValue)
    }
}
