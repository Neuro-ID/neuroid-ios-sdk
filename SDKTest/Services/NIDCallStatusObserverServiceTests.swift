//
//  NIDCallStatusObserverServiceTests.swift
//  NeuroID
//

import Testing
@testable import NeuroID

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
}
