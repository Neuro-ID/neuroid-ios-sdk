//
//  NIDForm.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation

public extension NeuroID {
    /**
     Form Submit, Sccuess & Failure
     */
    static func formSubmit() -> NIDEvent {
        let submitEvent = NIDEvent(type: NIDEventName.applicationSubmit)
        saveEventToLocalDataStore(submitEvent)
        NIDLog.i("**** NOTE: THIS METHOD IS DEPRECATED AND IS NO LONGER REQUIRED")
        return submitEvent
    }

    static func formSubmitFailure() -> NIDEvent {
        let submitEvent = NIDEvent(type: NIDEventName.applicationSubmitFailure)
        saveEventToLocalDataStore(submitEvent)
        NIDLog.i("**** NOTE: THIS METHOD IS DEPRECATED AND IS NO LONGER REQUIRED")
        return submitEvent
    }

    static func formSubmitSuccess() -> NIDEvent {
        let submitEvent = NIDEvent(type: NIDEventName.applicationSubmitSuccess)
        saveEventToLocalDataStore(submitEvent)
        NIDLog.i("**** NOTE: THIS METHOD IS DEPRECATED AND IS NO LONGER REQUIRED")
        return submitEvent
    }
}
