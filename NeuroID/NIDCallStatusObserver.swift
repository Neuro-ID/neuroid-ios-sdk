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
        //        Outgoing call answered
        if(call.isOutgoing && call.hasConnected && !call.hasEnded){
            UtilFunctions.captureCallStatusEvent(eventType: NIDEventName.callInProgress, status: CallInProgress.ACTIVE.rawValue, metadata: CallInProgressMetaData.OUTGOING_ANSWERED.rawValue)
            NIDLog.d("Outgoing call (answered) observed /could be voice mail")}
        //        Outgoing call ringing
        else if(call.isOutgoing && !call.hasConnected && !call.hasEnded){
            UtilFunctions.captureCallStatusEvent(eventType: NIDEventName.callInProgress, status: CallInProgress.INACTIVE.rawValue, metadata: CallInProgressMetaData.OUTGOING_RINGING.rawValue)
            NIDLog.d("Outgoing call (ringing) observed")}
        //        Outgoing call ended
        else if(call.isOutgoing && call.hasEnded){
            UtilFunctions.captureCallStatusEvent(eventType: NIDEventName.callInProgress, status: CallInProgress.INACTIVE.rawValue, metadata: CallInProgressMetaData.OUTGOING_ENDED.rawValue)
            NIDLog.d("Outgoing call ended")}
        //        Incoming call ringing
        else if(!call.isOutgoing && !call.hasConnected && !call.hasEnded){
            UtilFunctions.captureCallStatusEvent(eventType: NIDEventName.callInProgress, status: CallInProgress.INACTIVE.rawValue, metadata: CallInProgressMetaData.INCOMING_RINGING.rawValue)
            NIDLog.d("Incoming call (ringing) in progress is observed")}
        //        Incoming call answered
        else if(!call.isOutgoing && call.hasConnected && !call.hasEnded){
            UtilFunctions.captureCallStatusEvent(eventType: NIDEventName.callInProgress, status: CallInProgress.ACTIVE.rawValue, metadata: CallInProgressMetaData.INCOMING_ANSWERED.rawValue)
            NIDLog.d("Incoming call (answered)/voicemail in progress is observed")}
        //        Incoming call ended
        else if(!call.isOutgoing && call.hasEnded){
            UtilFunctions.captureCallStatusEvent(eventType: NIDEventName.callInProgress, status: CallInProgress.INACTIVE.rawValue, metadata: CallInProgressMetaData.INCOMING_ENDED.rawValue)
            NIDLog.d("Incoming call ended ")}
 
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
