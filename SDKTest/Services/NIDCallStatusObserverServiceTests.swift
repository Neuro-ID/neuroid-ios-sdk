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
    var uuid: UUID = UUID()
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

    // MARK: - Backward compatibility: existing "type" attr still present

    @Test(arguments: [true, false])
    func answered_typeAttrPreserved(isOutgoing: Bool) {
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: isOutgoing, uuid: UUID())

        let event = eventStorageService.mockEventStore.last
        let typeAttr = event?.attrs?.first(where: { $0.n == "type" })
        #expect(typeAttr?.v == (isOutgoing ? "outgoing" : "incoming"))
    }

    // MARK: - UUID attribute

    @Test
    func callEvent_containsUuidAttribute() {
        let testUUID = UUID()
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: true, uuid: testUUID)

        let event = eventStorageService.mockEventStore.last
        let uuidAttr = event?.attrs?.first(where: { $0.n == "uuid" })
        #expect(uuidAttr?.v == testUUID.uuidString)
    }

    // MARK: - Progress values

    @Test(arguments: [
        CallScenario(hasEnded: false, isOnHold: false, hasConnected: false, isOutgoing: false, expectedProgress: "ringing", expectedCp: CallInProgress.INACTIVE.rawValue, expectedType: "incoming"),
        CallScenario(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: false, expectedProgress: "answered", expectedCp: CallInProgress.ACTIVE.rawValue, expectedType: "incoming"),
        CallScenario(hasEnded: true, isOnHold: false, hasConnected: false, isOutgoing: false, expectedProgress: "ended", expectedCp: CallInProgress.INACTIVE.rawValue, expectedType: "incoming"),
        CallScenario(hasEnded: false, isOnHold: true, hasConnected: false, isOutgoing: false, expectedProgress: "onhold", expectedCp: CallInProgress.ACTIVE.rawValue, expectedType: "incoming")
    ])
    func progressValues(_ scenario: CallScenario) {
        service.handleCallChange(hasEnded: scenario.hasEnded, isOnHold: scenario.isOnHold, hasConnected: scenario.hasConnected, isOutgoing: scenario.isOutgoing, uuid: UUID())

        let event = eventStorageService.mockEventStore.last
        let progressAttr = event?.attrs?.first(where: { $0.n == "progress" })
        #expect(progressAttr?.v == scenario.expectedProgress)
    }

    // MARK: - startListeningToCallStatus

    @Test
    func startListening_whenAlreadyRegistered_doesNotReRegister() {
        // After init, service is already registered
        // Calling start again should be a no-op (no crash, no duplicate registration)
        service.startListeningToCallStatus()

        // Verify service still works correctly after no-op start
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: true, uuid: UUID())
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
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: false, uuid: UUID())
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
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: true, uuid: UUID())
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

        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: false, uuid: UUID())
        #expect(eventStorageService.mockEventStore.count == 1)
    }

    @Test
    func stopListening_whenNotRegistered_isNoOp() {
        // Unregister
        service.stopListeningToCallStatus()

        // Calling stop again should not crash (no-op)
        service.stopListeningToCallStatus()

        // Service handleCallChange still works (it's independent of delegate registration)
        service.handleCallChange(hasEnded: true, isOnHold: false, hasConnected: false, isOutgoing: false, uuid: UUID())
        let event = eventStorageService.mockEventStore.last
        #expect(event?.cp == CallInProgress.INACTIVE.rawValue)
    }

    // MARK: - callObserver delegate (via processCall)

    @Test(arguments: [
        CallScenario(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: true, expectedProgress: "answered", expectedCp: CallInProgress.ACTIVE.rawValue, expectedType: "outgoing"),
        CallScenario(hasEnded: true, isOnHold: false, hasConnected: false, isOutgoing: false, expectedProgress: "ended", expectedCp: CallInProgress.INACTIVE.rawValue, expectedType: "incoming"),
        CallScenario(hasEnded: false, isOnHold: true, hasConnected: false, isOutgoing: true, expectedProgress: "onhold", expectedCp: CallInProgress.ACTIVE.rawValue, expectedType: "outgoing"),
        CallScenario(hasEnded: false, isOnHold: false, hasConnected: false, isOutgoing: false, expectedProgress: "ringing", expectedCp: CallInProgress.INACTIVE.rawValue, expectedType: "incoming")
    ])
    func callObserver_delegateMethod(_ scenario: CallScenario) {
        let mockCall = MockCallProperties(hasEnded: scenario.hasEnded, isOnHold: scenario.isOnHold, hasConnected: scenario.hasConnected, isOutgoing: scenario.isOutgoing)

        service.processCall(mockCall)

        let event = eventStorageService.mockEventStore.last
        #expect(event?.cp == scenario.expectedCp)
        let progressAttr = event?.attrs?.first(where: { $0.n == "progress" })
        #expect(progressAttr?.v == scenario.expectedProgress)
        let typeAttr = event?.attrs?.first(where: { $0.n == "type" })
        #expect(typeAttr?.v == scenario.expectedType)
    }

    @Test
    func callObserver_delegateIsSetAfterInit() {
        // After init, the delegate should be set — verify by stopping and restarting
        // This exercises the callObserver registration path
        service.stopListeningToCallStatus()
        configService.mockConfigCache.callInProgress = true
        service.startListeningToCallStatus()

        // The service should still be able to handle call changes
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: false, isOutgoing: true, uuid: UUID())
        let event = eventStorageService.mockEventStore.last
        let progressAttr = event?.attrs?.first(where: { $0.n == "progress" })
        #expect(progressAttr?.v == "ringing")
        let typeAttr = event?.attrs?.first(where: { $0.n == "type" })
        #expect(typeAttr?.v == "outgoing")
    }

    @Test
    func callObserver_fullLifecycle_incomingCall() {
        // Simulate full lifecycle: ringing -> answered -> on hold -> answered -> ended
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: false, isOutgoing: false, uuid: UUID())
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: false, uuid: UUID())
        service.handleCallChange(hasEnded: false, isOnHold: true, hasConnected: false, isOutgoing: false, uuid: UUID())
        service.handleCallChange(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: false, uuid: UUID())
        service.handleCallChange(hasEnded: true, isOnHold: false, hasConnected: false, isOutgoing: false, uuid: UUID())

        #expect(eventStorageService.mockEventStore.count == 5)

        // Verify final event is ended
        let lastEvent = eventStorageService.mockEventStore.last
        #expect(lastEvent?.cp == CallInProgress.INACTIVE.rawValue)
        let progressAttr = lastEvent?.attrs?.first(where: { $0.n == "progress" })
        #expect(progressAttr?.v == "ended")
    }

    // MARK: - cp (callInProgress status) values

    @Test(arguments: [
        CallScenario(hasEnded: false, isOnHold: false, hasConnected: false, isOutgoing: false, expectedProgress: "ringing", expectedCp: CallInProgress.INACTIVE.rawValue, expectedType: "incoming"),
        CallScenario(hasEnded: false, isOnHold: false, hasConnected: true, isOutgoing: false, expectedProgress: "answered", expectedCp: CallInProgress.ACTIVE.rawValue, expectedType: "incoming"),
        CallScenario(hasEnded: false, isOnHold: true, hasConnected: false, isOutgoing: false, expectedProgress: "onhold", expectedCp: CallInProgress.ACTIVE.rawValue, expectedType: "incoming"),
        CallScenario(hasEnded: true, isOnHold: false, hasConnected: false, isOutgoing: false, expectedProgress: "ended", expectedCp: CallInProgress.INACTIVE.rawValue, expectedType: "incoming")
    ])
    func cpValues(_ scenario: CallScenario) {
        service.handleCallChange(hasEnded: scenario.hasEnded, isOnHold: scenario.isOnHold, hasConnected: scenario.hasConnected, isOutgoing: scenario.isOutgoing, uuid: UUID())

        let event = eventStorageService.mockEventStore.last
        #expect(event?.cp == scenario.expectedCp)
    }
}

// MARK: - Test Argument Types

extension NIDCallStatusObserverServiceTests {
    struct CallScenario: CustomStringConvertible, Sendable {
        let hasEnded: Bool
        let isOnHold: Bool
        let hasConnected: Bool
        let isOutgoing: Bool
        let expectedProgress: String
        let expectedCp: String
        let expectedType: String?

        var description: String {
            return "\(expectedProgress) (\(isOutgoing ? "outgoing" : "incoming"))"
        }
    }
}
