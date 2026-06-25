//
//  NIDCallStatusObserver.swift
//  NeuroID
//
//  Created by Priya Xavier on 1/26/24.
//

import CallKit
import Foundation

protocol CallStatusObserverServiceProtocol {
    func startListeningToCallStatus()
    func stopListeningToCallStatus()
}

class NIDCallStatusObserverService: NSObject, CXCallObserverDelegate, CallStatusObserverServiceProtocol {
    private let callObserver = CXCallObserver()
    private var isRegistered = false
    private var callStates: [UUID: CallPhase] = [:]

    private let eventStorageService: EventStorageServiceProtocol
    private let configService: ConfigServiceProtocol

    init(
        eventStorageService: EventStorageServiceProtocol,
        configService: ConfigServiceProtocol
    ) {
        self.eventStorageService = eventStorageService
        self.configService = configService
        super.init()
        self.callObserver.setDelegate(self, queue: nil)
        self.isRegistered = true
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

        self.eventStorageService.saveEventToLocalDataStore(
            NIDEvent(
                type: .callInProgress,
                attrs: attrs,
                cp: state.rawValue
            )
        )
    }

    func startListeningToCallStatus() {
        if !self.isRegistered {
            if self.configService.configCache.callInProgress {
                self.callObserver.setDelegate(self, queue: nil)
                self.isRegistered = true
            }
        }
    }

    func stopListeningToCallStatus() {
        if self.isRegistered {
            self.callObserver.setDelegate(nil, queue: nil)
            self.isRegistered = false
            self.callStates.removeAll()
        }
    }
}

extension NIDCallStatusObserverService {
    enum CallPhase: String {
        case connected, disconnected, onHold
    }

    enum Direction: String {
        case incoming, outgoing
    }
}
