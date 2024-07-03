//
//  NIDCallStatusObserver.swift
//  NeuroID
//
//  Created by Priya Xavier on 1/26/24.
//

import CallKit
import Foundation

class NIDCallStatusObserver: NSObject, CXCallObserverDelegate {
    private let callObserver = CXCallObserver()
    private var isRegistered = false
    
    override init() {
        super.init()
        self.callObserver.setDelegate(self, queue: nil)
        self.isRegistered = true
    }
    
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        var status: String
        var attrs: Attrs
        
        if call.hasEnded {
            status = CallInProgress.INACTIVE.rawValue
            attrs = Attrs(n: call.isOutgoing ? CallInProgressMetaData.OUTGOING.rawValue : CallInProgressMetaData.INCOMING.rawValue,
                          v: CallInProgressMetaData.ENDED.rawValue)
            
        } else if call.isOnHold {
            status = CallInProgress.ACTIVE.rawValue
            attrs = Attrs(n: call.isOutgoing ? CallInProgressMetaData.OUTGOING.rawValue : CallInProgressMetaData.INCOMING.rawValue,
                          v: CallInProgressMetaData.ONHOLD.rawValue)
            
        } else if call.hasConnected {
            status = CallInProgress.ACTIVE.rawValue
            attrs = Attrs(n: call.isOutgoing ? CallInProgressMetaData.OUTGOING.rawValue : CallInProgressMetaData.INCOMING.rawValue,
                          v: CallInProgressMetaData.ANSWERED.rawValue)
            
        } else {
            status = CallInProgress.INACTIVE.rawValue
            attrs = Attrs(n: call.isOutgoing ? CallInProgressMetaData.OUTGOING.rawValue : CallInProgressMetaData.INCOMING.rawValue,
                          v: CallInProgressMetaData.RINGING.rawValue)
            
        }
        
        UtilFunctions.captureCallStatusEvent(eventType: NIDEventName.callInProgress, status: status, attrs: attrs)
    }
    
    func startListeningToCallStatus() {
        if !self.isRegistered {
            if NeuroID.configService.configCache.callInProgress {
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
