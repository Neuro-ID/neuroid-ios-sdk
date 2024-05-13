//
//  NIDCallStatusObserver.swift
//  NeuroID
//
//  Created by Priya Xavier on 1/26/24.
//

import Foundation
import CallKit

class NIDCallStatusObserver: NSObject, CXCallObserverDelegate {
    private let callObserver = CXCallObserver()
    private var isRegistered = false
    
    override init() {
        super.init()
        self.callObserver.setDelegate(self, queue: nil)
        isRegistered = true
    }
    
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        if call.hasEnded{
            UtilFunctions.captureCallStatusEvent(eventType: NIDEventName.callInProgress, status: CallInProgress.INACTIVE.rawValue)
            NIDLog.d("Call has ended")
        } else if call.isOutgoing {
            UtilFunctions.captureCallStatusEvent(eventType: NIDEventName.callInProgress, status: CallInProgress.ACTIVE.rawValue)
            NIDLog.d("Ongoing call observed")
        } else if call.hasConnected {
            // Event not captured
            NIDLog.d("Call connected")
        } else if call.isOnHold {
            // Event not captured
            NIDLog.d("Call on hold")
        } else {
            UtilFunctions.captureCallStatusEvent(eventType: NIDEventName.callInProgress, status: CallInProgress.ACTIVE.rawValue)
            NIDLog.d("Incoming Call observed")
        }
    }
    
    func startListeningToCallStatus(){
        if(!isRegistered) {
            if (NeuroID.configService.configCache.callInProgress) {
                self.callObserver.setDelegate(self, queue: nil)
                self.isRegistered = true
            }
        }
    }
    
    func stopListeningToCallStatus(){
        if(isRegistered){
            self.callObserver.setDelegate(nil, queue: nil)
            isRegistered = false
        }
    }
}
