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

    @Test(arguments: [true, false])
    func `emits connected with direction and id when a call connects`(isOutgoing: Bool) {
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

    @Test
    func `emits onHold with direction and id after a connected call is placed on hold`() {
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

    @Test
    func `emits connected again when a held call becomes active`() {
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

    @Test
    func `emits disconnected with direction and id when a tracked call ends`() {
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

    @Test
    func `emits disconnected when the first observed state is ended`() {
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

    @Test
    func `emits nothing for calls that are only ringing`() {
        callService.processCallChange(
            hasEnded: false,
            isOnHold: false,
            hasConnected: false,
            direction: .incoming,
            callID: UUID()
        )

        #expect(eventStorageService.mockEventStore.isEmpty)
    }

    @Test
    func `does not eemit duplicate events for repeated callbacks of the same state`() {
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

    @Test
    func `emits only onHold when the first observed state is on hold`() {
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

    @Test
    func `tracks simultaneous calls independetly`() {
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
