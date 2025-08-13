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
        var status: String
        var attrs: [Attrs] = []
        var progress: String
        
        // Add call type
        attrs.append(Attrs(n: "type", v: call.isOutgoing ? CallInProgressMetaData.OUTGOING.rawValue : CallInProgressMetaData.INCOMING.rawValue))
        
        if call.hasEnded {
            status = CallInProgress.INACTIVE.rawValue
            progress = CallInProgressMetaData.ENDED.rawValue
            
        } else if call.isOnHold {
            status = CallInProgress.ACTIVE.rawValue
            progress = CallInProgressMetaData.ONHOLD.rawValue
            
        } else if call.hasConnected {
            status = CallInProgress.ACTIVE.rawValue
            progress = CallInProgressMetaData.ANSWERED.rawValue
            
        } else {
            status = CallInProgress.INACTIVE.rawValue
            progress = CallInProgressMetaData.RINGING.rawValue
        }
        
        // Add call progress
        attrs.append(Attrs(n: "progress", v: progress))
        
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
