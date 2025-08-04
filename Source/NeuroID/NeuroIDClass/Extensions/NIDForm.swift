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
    @available(*, deprecated, message: "formSubmit is deprecated and no longer required")
    static func formSubmit() -> NIDEvent {
        let submitEvent = NIDEvent(type: NIDEventName.applicationSubmit)
        saveEventToLocalDataStore(submitEvent)
        logger.i("**** NOTE: THIS METHOD IS DEPRECATED AND IS NO LONGER REQUIRED")
        return submitEvent
    }

    @available(*, deprecated, message: "formSubmitFailure is deprecated and no longer required")
    static func formSubmitFailure() -> NIDEvent {
        let submitEvent = NIDEvent(type: NIDEventName.applicationSubmitFailure)
        saveEventToLocalDataStore(submitEvent)
        logger.i("**** NOTE: THIS METHOD IS DEPRECATED AND IS NO LONGER REQUIRED")
        return submitEvent
    }

    @available(*, deprecated, message: "formSubmitSuccess is deprecated and no longer required")
    static func formSubmitSuccess() -> NIDEvent {
        let submitEvent = NIDEvent(type: NIDEventName.applicationSubmitSuccess)
        saveEventToLocalDataStore(submitEvent)
        logger.i("**** NOTE: THIS METHOD IS DEPRECATED AND IS NO LONGER REQUIRED")
        return submitEvent
    }
}
