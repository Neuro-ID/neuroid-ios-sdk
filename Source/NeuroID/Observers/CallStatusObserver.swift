//
//  CallStatusObserver.swift
//  NeuroID
//

import CallKit
import Foundation

final class CallStatusObserver: NSObject, CXCallObserverDelegate, SessionObserver, @unchecked Sendable {
    private let eventService: EventStorageServiceProtocol
    private let callObserver = CXCallObserver()

    private var callStates: [UUID: CallPhase] = [:]

    init(eventService: EventStorageServiceProtocol) {
        self.eventService = eventService
        super.init()
    }

    func start() {
        callObserver.setDelegate(self, queue: nil)
    }

    func stop() {
        callObserver.setDelegate(nil, queue: nil)
        callStates.removeAll()
    }

    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        processCallChange(
            hasEnded: call.hasEnded,
            isOnHold: call.isOnHold,
            hasConnected: call.hasConnected,
            direction: call.isOutgoing ? .outgoing : .incoming,
            callID: call.uuid
        )
    }

    func processCallChange(
        hasEnded: Bool, isOnHold: Bool, hasConnected: Bool, direction: Direction, callID: UUID
    ) {
        let previousPhase = callStates[callID]

        if hasEnded {
            guard previousPhase != .disconnected else { return }

            emitCallEvent(
                state: .disconnected,
                direction: direction,
                callID: callID
            )
            callStates[callID] = .disconnected
            return
        }

        if isOnHold {
            guard previousPhase != .onHold else { return }

            emitCallEvent(
                state: .onHold,
                direction: direction,
                callID: callID
            )
            callStates[callID] = .onHold
            return
        }

        if hasConnected {
            guard previousPhase != .connected else { return }

            emitCallEvent(
                state: .connected,
                direction: direction,
                callID: callID
            )
            callStates[callID] = .connected
            return
        }
    }

    private func emitCallEvent(state: CallPhase, direction: Direction, callID: UUID) {
        let attrs = [
            Attrs(n: "direction", v: direction.rawValue),
            Attrs(n: "id", v: callID.uuidString)
        ]

        self.eventService.saveEventToLocalDataStore(
            NIDEvent(
                type: .callInProgress,
                attrs: attrs,
                cp: state.rawValue
            )
        )
    }
}

extension CallStatusObserver {
    enum CallPhase: String {
        case connected, disconnected, onHold
    }

    enum Direction: String {
        case incoming, outgoing
    }
}
