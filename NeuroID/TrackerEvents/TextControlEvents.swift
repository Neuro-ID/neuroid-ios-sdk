//
//  TextControlEvents.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

// MARK: - Text control events

internal extension NeuroIDTracker {
    func observeTextInputEvents() {
        // UITextField
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textBeginEditing),
                                               name: UITextField.textDidBeginEditingNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textChange),
                                               name: UITextField.textDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textEndEditing),
                                               name: UITextField.textDidEndEditingNotification,
                                               object: nil)

        // UITextView
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textBeginEditing),
                                               name: UITextView.textDidBeginEditingNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textChange),
                                               name: UITextView.textDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textEndEditing),
                                               name: UITextView.textDidEndEditingNotification,
                                               object: nil)
    }

    @objc func textBeginEditing(notification: Notification) {
        logTextEvent(from: notification, eventType: .focus)
    }

    @objc func textChange(notification: Notification) {
        logTextEvent(from: notification, eventType: .input)
    }

    @objc func textEndEditing(notification: Notification) {
        logTextEvent(from: notification, eventType: .blur)
    }

    /**
     Target values:
        ETN - Input
        ET - human readable tag
     */

    func logTextEvent(from notification: Notification, eventType: NIDEventName) {
        switch notification.object {
            case is UITextField:

                let textControl = notification.object as! UITextField
                _ = NeuroIDTracker.registerViewIfNotRegistered(view: textControl)

                UtilFunctions.captureTextEvents(view: textControl, textValue: textControl.text ?? "", eventType: eventType)
            case is UITextView:
                let textControl = notification.object as! UITextView
                _ = NeuroIDTracker.registerViewIfNotRegistered(view: textControl)

                UtilFunctions.captureTextEvents(view: textControl, textValue: textControl.text ?? "", eventType: eventType)

            default:
                NIDDebugPrint(tag: Constants.extraInfoTag.rawValue, "No known text object")
        }

        // DO WE WANT THIS?
        if let textControl = notification.object as? UISearchBar {
            let id = textControl.id
            let tg = ParamsCreator.getTGParamsForInput(eventName: eventType, view: textControl, type: "UISearchBar", attrParams: nil)
            let searchEvent = NIDEvent(type: eventType, tg: tg)
            searchEvent.tgs = TargetValue.string(id).toString()
            captureEvent(event: searchEvent)
        }
    }
}
