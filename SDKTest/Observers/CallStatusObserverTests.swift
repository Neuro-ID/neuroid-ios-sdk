//
//  CallStatusObserverTests.swift
//  NeuroID
//

import Foundation
import Testing

@testable import NeuroID

@Suite
struct CallStatusObserverTests {
    let dataStore: DataStore
    let eventService: EventStorageService
    let callService: CallStatusObserver

    init() {
        dataStore = DataStore()
        eventService = EventStorageService()

        NeuroIDCore.shared.datastore = dataStore
        NeuroIDCore.shared._isSDKStarted = true

        callService = CallStatusObserver(
            eventService: eventService
        )
    }

    @Test(
        "Emits connected with direction and id when a call connects",
        arguments: [CallStatusObserver.Direction.incoming, CallStatusObserver.Direction.outgoing]
    )
    func emitsConnectedEvent(direction: CallStatusObserver.Direction) async {
        let callID = UUID()

        callService.processCallChange(
            hasEnded: false,
            isOnHold: false,
            hasConnected: true,
            direction: direction,
            callID: callID
        )

        let events = dataStore.getAndRemoveAllEvents()

        assertLastEvent(
            events.last,
            state: .connected,
            direction: direction,
            callID: callID
        )
    }

    @Test("Emits onHold with direction and id after a connected call is placed on hold")
    func emitsOnHoldAfterConnected() async {
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

        let events = dataStore.getAndRemoveAllEvents()

        #expect(events.count == 2)
        assertLastEvent(
            events.last,
            state: .onHold,
            direction: .outgoing,
            callID: callID
        )
    }

    @Test("Emits connected again when a held call becomes active")
    func emitsConnectedWhenResumedFromHold() async {
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

        let events = dataStore.getAndRemoveAllEvents()

        #expect(events.count == 3)
        #expect(callStates(events) == [.connected, .onHold, .connected])
        assertLastEvent(
            events.last,
            state: .connected,
            direction: .incoming,
            callID: callID
        )
    }

    @Test("Emits disconnected with direction and id when a tracked call ends")
    func emitsDisconnectedWhenTrackedCallEnds() async {
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

        let events = dataStore.getAndRemoveAllEvents()
        #expect(events.count == 2)
        assertLastEvent(
            events.last,
            state: .disconnected,
            direction: .outgoing,
            callID: callID
        )
    }

    @Test("Emits disconnected when the first observed state is ended")
    func emitsDisconnectedWhenFirstStateIsEnded() async {
        let callID = UUID()

        callService.processCallChange(
            hasEnded: true,
            isOnHold: false,
            hasConnected: true,
            direction: .incoming,
            callID: callID
        )

        let events = dataStore.getAndRemoveAllEvents()
        #expect(events.count == 1)
        assertLastEvent(
            events.last,
            state: .disconnected,
            direction: .incoming,
            callID: callID
        )
    }

    @Test("Emits nothing for calls that are only ringing")
    func emitsNothingForRingingOnly() async {
        callService.processCallChange(
            hasEnded: false,
            isOnHold: false,
            hasConnected: false,
            direction: .incoming,
            callID: UUID()
        )

        #expect(await dataStore.getAllEventCount() == 0)
    }

    @Test("Does not emit duplicate events for repeated callbacks of the same state")
    func doesNotEmitDuplicateEvents() async {
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

        let events = dataStore.getAndRemoveAllEvents()
        #expect(events.count == 3)
        #expect(callStates(events) == [.connected, .onHold, .disconnected])
    }

    @Test("Emits only onHold when the first observed state is on hold")
    func emitsOnHoldWhenFirstStateIsOnHold() async {
        let callID = UUID()

        callService.processCallChange(
            hasEnded: false,
            isOnHold: true,
            hasConnected: false,
            direction: .incoming,
            callID: callID
        )

        let events = dataStore.getAndRemoveAllEvents()
        #expect(events.count == 1)
        #expect(callStates(events) == [.onHold])
        assertLastEvent(
            events.last,
            state: .onHold,
            direction: .incoming,
            callID: callID
        )
    }

    @Test("Tracks simultaneous calls independently")
    func tracksSimultaneousCalls() async {
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

        let events = dataStore.getAndRemoveAllEvents()
        #expect(events.count == 5)
        #expect(callStates(events) == [.connected, .onHold, .connected, .disconnected, .disconnected])
    }

    private func assertLastEvent(
        _ lastEvent: NIDEvent?,
        state: CallStatusObserver.CallPhase,
        direction: CallStatusObserver.Direction,
        callID: UUID
    ) {
        #expect(lastEvent?.cp == state.rawValue)
        #expect(lastEvent?.attrs?.first(where: { $0.n == "direction" })?.v == direction.rawValue)
        #expect(lastEvent?.attrs?.first(where: { $0.n == "id" })?.v == callID.uuidString)
    }

    func callStates(_ events: [NIDEvent]) -> [CallStatusObserver.CallPhase] {
        events.compactMap {
            CallStatusObserver.CallPhase(rawValue: $0.cp!)
        }
    }

    @Test("start and stop record no events on their own")
    func startStopRecordNoEvents() async {
        callService.start()
        callService.stop()

        let events = dataStore.getAndRemoveAllEvents()
        #expect(events.isEmpty)
    }

    @Test("start and stop can called repeatedly without crashing")
    func repeatedStartStopIsSafe() async {
        callService.start()
        callService.start()
        callService.stop()
        callService.stop()

        let events = dataStore.getAndRemoveAllEvents()
        #expect(events.isEmpty)
    }

}
