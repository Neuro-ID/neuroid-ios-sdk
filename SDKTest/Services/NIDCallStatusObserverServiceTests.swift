//
//  NIDCallStatusObserverService.swift
//  NeuroID
//

import Foundation
import Testing

@testable import NeuroID

@Suite
struct NIDCallStatusObserverServiceTests {
    var eventStorageService: MockEventStorageService
    var configService: MockConfigService
    var callService: NIDCallStatusObserverService

    init() {
        eventStorageService = MockEventStorageService()
        configService = MockConfigService()
        callService = NIDCallStatusObserverService(
            eventStorageService: eventStorageService,
            configService: configService
        )
    }

    @Test("emits connected with direction and id when a call connects", arguments: [true, false])
    func emitsConnectedEvent(isOutgoing: Bool) {
        let callID = UUID()
        let direction: NIDCallStatusObserverService.Direction = isOutgoing ? .outgoing : .incoming

        callService.processCallChange(
            hasEnded: false,
            isOnHold: false,
            hasConnected: true,
            direction: direction,
            callID: callID
        )

        assertLastEvent(
            state: .connected,
            direction: direction,
            callID: callID
        )
    }

    @Test("emits onHold with direction and id after a connected call is placed on hold")
    func emitsOnHoldAfterConnected() {
        let callID = UUID()

        callService.processCallChange(
            hasEnded: false,
            isOnHold: false,
            hasConnected: true,
            direction: .outgoing,
            callID: callID
        )

        callService.processCallChange(
            hasEnded: false,
            isOnHold: true,
            hasConnected: false,
            direction: .outgoing,
            callID: callID
        )

        #expect(eventStorageService.mockEventStore.count == 2)
        assertLastEvent(
            state: .onHold,
            direction: .outgoing,
            callID: callID
        )
    }

    @Test("emits connected again when a held call becomes active")
    func emitsConnectedWhenResumedFromHold() {
        let callID = UUID()

        callService.processCallChange(
            hasEnded: false,
            isOnHold: false,
            hasConnected: true,
            direction: .incoming,
            callID: callID
        )
        callService.processCallChange(
            hasEnded: false,
            isOnHold: true,
            hasConnected: false,
            direction: .incoming,
            callID: callID
        )
        callService.processCallChange(
            hasEnded: false,
            isOnHold: false,
            hasConnected: true,
            direction: .incoming,
            callID: callID
        )

        #expect(eventStorageService.mockEventStore.count == 3)
        #expect(callStates() == [.connected, .onHold, .connected])
        assertLastEvent(
            state: .connected,
            direction: .incoming,
            callID: callID
        )
    }

    @Test("emits disconnected with direction and id when a tracked call ends")
    func emitsDisconnectedWhenTrackedCallEnds() {
        let callID = UUID()

        callService.processCallChange(
            hasEnded: false,
            isOnHold: false,
            hasConnected: true,
            direction: .outgoing,
            callID: callID
        )

        callService.processCallChange(
            hasEnded: true,
            isOnHold: false,
            hasConnected: false,
            direction: .outgoing,
            callID: callID
        )

        #expect(eventStorageService.mockEventStore.count == 2)
        assertLastEvent(
            state: .disconnected,
            direction: .outgoing,
            callID: callID
        )
    }

    @Test("emits disconnected when the first observed state is ended")
    func emitsDisconnectedWhenFirstStateIsEnded() {
        let callID = UUID()

        callService.processCallChange(
            hasEnded: true,
            isOnHold: false,
            hasConnected: true,
            direction: .incoming,
            callID: callID
        )

        #expect(eventStorageService.mockEventStore.count == 1)
        assertLastEvent(
            state: .disconnected,
            direction: .incoming,
            callID: callID
        )
    }

    @Test("emits nothing for calls that are only ringing")
    func emitsNothingForRingingOnly() {
        callService.processCallChange(
            hasEnded: false,
            isOnHold: false,
            hasConnected: false,
            direction: .incoming,
            callID: UUID()
        )

        #expect(eventStorageService.mockEventStore.isEmpty)
    }

    @Test("does not eemit duplicate events for repeated callbacks of the same state")
    func doesNotEmitDuplicateEvents() {
        let callID = UUID()

        callService.processCallChange(
            hasEnded: false,
            isOnHold: false,
            hasConnected: true,
            direction: .outgoing,
            callID: callID
        )
        callService.processCallChange(
            hasEnded: false,
            isOnHold: false,
            hasConnected: true,
            direction: .outgoing,
            callID: callID
        )
        callService.processCallChange(
            hasEnded: false,
            isOnHold: true,
            hasConnected: false,
            direction: .outgoing,
            callID: callID
        )
        callService.processCallChange(
            hasEnded: false,
            isOnHold: true,
            hasConnected: false,
            direction: .outgoing,
            callID: callID
        )
        callService.processCallChange(
            hasEnded: true,
            isOnHold: false,
            hasConnected: false,
            direction: .outgoing,
            callID: callID
        )
        callService.processCallChange(
            hasEnded: true,
            isOnHold: false,
            hasConnected: false,
            direction: .outgoing,
            callID: callID
        )

        #expect(eventStorageService.mockEventStore.count == 3)
        #expect(callStates() == [.connected, .onHold, .disconnected])
    }

    @Test("emits only onHold when the first observed state is on hold")
    func emitsOnHoldWhenFirstStateIsOnHold() {
        let callID = UUID()

        callService.processCallChange(
            hasEnded: false,
            isOnHold: true,
            hasConnected: false,
            direction: .incoming,
            callID: callID
        )

        #expect(eventStorageService.mockEventStore.count == 1)
        #expect(callStates() == [.onHold])
        assertLastEvent(
            state: .onHold,
            direction: .incoming,
            callID: callID
        )
    }

    @Test("tracks simultaneous calls independetly")
    func tracksSimultaneousCalls() {
        let firstCallID = UUID()
        let secondCallID = UUID()

        callService.processCallChange(
            hasEnded: false,
            isOnHold: false,
            hasConnected: true,
            direction: .incoming,
            callID: firstCallID
        )
        callService.processCallChange(
            hasEnded: false,
            isOnHold: true,
            hasConnected: false,
            direction: .incoming,
            callID: firstCallID
        )
        callService.processCallChange(
            hasEnded: false,
            isOnHold: false,
            hasConnected: true,
            direction: .outgoing,
            callID: secondCallID
        )
        callService.processCallChange(
            hasEnded: true,
            isOnHold: false,
            hasConnected: false,
            direction: .outgoing,
            callID: secondCallID
        )
        callService.processCallChange(
            hasEnded: true,
            isOnHold: false,
            hasConnected: false,
            direction: .incoming,
            callID: firstCallID
        )

        #expect(eventStorageService.mockEventStore.count == 5)
        #expect(callStates() == [.connected, .onHold, .connected, .disconnected, .disconnected])
    }

    private func assertLastEvent(
        state: NIDCallStatusObserverService.CallPhase,
        direction: NIDCallStatusObserverService.Direction,
        callID: UUID
    ) {
        let lastEvent = eventStorageService.mockEventStore.last

        #expect(lastEvent?.cp == state.rawValue)
        #expect(lastEvent?.attrs?.first(where: { $0.n == "direction" })?.v == direction.rawValue)
        #expect(lastEvent?.attrs?.first(where: { $0.n == "id" })?.v == callID.uuidString)
    }

    func callStates() -> [NIDCallStatusObserverService.CallPhase] {
        eventStorageService.mockEventStore.compactMap {
            NIDCallStatusObserverService.CallPhase(rawValue: $0.cp!)
        }
    }
}
