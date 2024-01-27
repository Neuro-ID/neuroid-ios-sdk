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
        override init() {
            super.init()
            self.callObserver.setDelegate(self, queue: nil)
        }

    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        if call.hasEnded{
            UtilFunctions.captureCallStatusEvent(eventType: NIDEventName.callStatus, status: CallStatus.ENDED.rawValue)
            NIDLog.d("Call has ended")
        }else if call.isOutgoing {
            UtilFunctions.captureCallStatusEvent(eventType: NIDEventName.callStatus, status: CallStatus.OUTGOING.rawValue)
            NIDLog.d("Ongoing call observed")
        } else if call.hasConnected {
            UtilFunctions.captureCallStatusEvent(eventType: NIDEventName.callStatus, status: CallStatus.CONNECTED.rawValue)
            NIDLog.d("Call connected")
        } else if call.isOnHold {
            UtilFunctions.captureCallStatusEvent(eventType: NIDEventName.callStatus, status: CallStatus.ON_HOLD.rawValue)
            NIDLog.d("Call on hold")
        } else {
            UtilFunctions.captureCallStatusEvent(eventType: NIDEventName.callStatus, status: CallStatus.OTHER.rawValue)
            NIDLog.d("Call status unrecognized")
        }
    }


}
