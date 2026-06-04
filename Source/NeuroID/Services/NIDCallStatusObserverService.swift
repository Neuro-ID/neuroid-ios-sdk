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

protocol CallProperties {
    var hasEnded: Bool { get }
    var isOnHold: Bool { get }
    var hasConnected: Bool { get }
    var isOutgoing: Bool { get }
    var uuid: UUID { get }
}

extension CXCall: CallProperties {}

class NIDCallStatusObserverService: NSObject, CXCallObserverDelegate, CallStatusObserverServiceProtocol {
    private let callObserver = CXCallObserver()
    private var isRegistered = false

    internal var callStartTime: Int64 = 0
    
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
        processCall(call)
    }

    // Internal entry point that accepts the CallProperties protocol for testability
    internal func processCall(_ call: CallProperties) {
        handleCallChange(
            hasEnded: call.hasEnded,
            isOnHold: call.isOnHold,
            hasConnected: call.hasConnected,
            isOutgoing: call.isOutgoing,
            uuid: call.uuid
        )
    }

    // Internal entry point extracted for testability (CXCall cannot be instantiated in unit tests)
    func handleCallChange(hasEnded: Bool, isOnHold: Bool, hasConnected: Bool, isOutgoing: Bool, uuid: UUID) {
        var status: String
        var attrs: [Attrs] = []
        var progress: String

        // Add call type (existing attr — kept for backward compatibility)
        attrs.append(Attrs(n: "type", v: isOutgoing ? CallInProgressMetaData.OUTGOING.rawValue : CallInProgressMetaData.INCOMING.rawValue))

        if hasEnded {
            status = CallInProgress.INACTIVE.rawValue
            progress = CallInProgressMetaData.ENDED.rawValue

        } else if isOnHold {
            status = CallInProgress.ACTIVE.rawValue
            progress = CallInProgressMetaData.ONHOLD.rawValue

        } else if hasConnected {
            status = CallInProgress.ACTIVE.rawValue
            progress = CallInProgressMetaData.ANSWERED.rawValue

        } else {
            status = CallInProgress.INACTIVE.rawValue
            progress = CallInProgressMetaData.RINGING.rawValue
        }

        // Add call progress
        attrs.append(Attrs(n: "progress", v: progress))
        attrs.append(Attrs(n: "uuid", v: uuid.uuidString))

        self.eventStorageService.saveEventToLocalDataStore(
            NIDEvent(
                type: .callInProgress,
                attrs: attrs,
                cp: status
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
        }
    }
}
