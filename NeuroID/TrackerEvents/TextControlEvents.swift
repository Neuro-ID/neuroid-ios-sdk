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
        //                // Keydown - DO WE WANT THIS?
        //                let keydownTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.keyDown, view: textControl, type: inputType, attrParams: ["v": lengthValue, "hash": textControl.text ?? ""])
        //                var keyDownEvent = NIDEvent(type: NIDEventName.keyDown, tg: keydownTG)
        //                keyDownEvent.v = lengthValue
        //                keyDownEvent.tgs = TargetValue.string(id).toString()
        ////                keyDownEvent.hv = hashValue
        //                captureEvent(event: keyDownEvent)

        switch notification.object {
            case is UITextField:

                let textControl = notification.object as! UITextField
                NeuroIDTracker.registerViewIfNotRegistered(view: textControl)

                if textControl.isSensitiveEntry() {
                    return
                }

                UtilFunctions.captureTextEvents(view: textControl, textValue: textControl.text ?? "", eventType: eventType)
            case is UITextView:
                let textControl = notification.object as! UITextView
                NeuroIDTracker.registerViewIfNotRegistered(view: textControl)

                if textControl.isSensitiveEntry() {
                    return
                }

                UtilFunctions.captureTextEvents(view: textControl, textValue: textControl.text ?? "", eventType: eventType)

            default:
                NIDDebugPrint(tag: Constants.extraInfoTag.rawValue, "No known text object")
        }

        // DO WE WANT THIS?
        if let textControl = notification.object as? UISearchBar {
            let id = textControl.id
            let tg = ParamsCreator.getTGParamsForInput(eventName: eventType, view: textControl, type: "UISearchBar", attrParams: nil)
            var searchEvent = NIDEvent(type: eventType, tg: tg)
            searchEvent.tgs = TargetValue.string(id).toString()
            captureEvent(event: searchEvent)
        }
    }

    func calcSimilarity(previousValue: String, currentValue: String) -> Double {
        var longer = previousValue
        var shorter = currentValue

        if previousValue.count < currentValue.count {
            longer = currentValue
            shorter = previousValue
        }
        let longerLength = Double(longer.count)

        if longerLength == 0 {
            return 1
        }

        return round(((longerLength - Double(levDis(longer, shorter))) / longerLength) * 100) / 100.0
    }

    func levDis(_ w1: String, _ w2: String) -> Int {
        let empty = [Int](repeating: 0, count: w2.count)
        var last = [Int](0 ... w2.count)

        for (i, char1) in w1.enumerated() {
            var cur = [i + 1] + empty
            for (j, char2) in w2.enumerated() {
                cur[j + 1] = char1 == char2 ? last[j] : min(last[j], last[j + 1], cur[j]) + 1
            }
            last = cur
        }
        return last.last!
    }

    func percentageDifference(newNumOrig: String, originalNumOrig: String) -> Double {
        let originalNum = originalNumOrig.replacingOccurrences(of: " ", with: "")
        let newNum = newNumOrig.replacingOccurrences(of: " ", with: "")

        guard var originalNumParsed = Double(originalNum) else {
            return -1
        }

        guard var newNumParsed = Double(newNum) else {
            return -1
        }

        if originalNumParsed <= 0 {
            originalNumParsed = 1
        }

        if newNumParsed <= 0 {
            newNumParsed = 1
        }

        return round(Double((newNumParsed - originalNumParsed) / originalNumParsed) * 100) / 100.0
    }
}
