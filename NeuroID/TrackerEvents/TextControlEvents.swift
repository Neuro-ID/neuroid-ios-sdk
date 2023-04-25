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

        // UIDatePicker
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(textBeginEditing),
//                                               name: UIDatePicker.,
//                                               object: nil)
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(textChange),
//                                               name: UITextView.textDidChangeNotification,
//                                               object: nil)
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(textEndEditing),
//                                               name: UITextView.textDidEndEditingNotification,
//                                               object: nil)
    }

    @objc func textBeginEditing(notification: Notification) {
        if let textControl = notification.object as? UITextField {
            // Touch event start
            // TODO, this begin editing could eventually be an invisible view over the input item to be a true tap...
            touchEvent(sender: textControl, eventName: .touchStart)
        } else if let textControl = notification.object as? UITextView {
            // Touch event start
            touchEvent(sender: textControl, eventName: .touchStart)
        }
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
        if let textControl = notification.object as? UITextField {
            NeuroIDTracker.registerViewIfNotRegistered(view: textControl)

            // isSecureText
            if #available(iOS 11.0, *) {
                if textControl.textContentType == .password || textControl.isSecureTextEntry { return }
            }
            if #available(iOS 12.0, *) {
                if textControl.textContentType == .newPassword { return }
            }

            let inputType = "text"
            let textValue = textControl.text ?? ""
            let lengthValue = "S~C~~\(textControl.text?.count ?? 0)"
            let hashValue = textControl.text?.sha256().prefix(8).string
            let tgs = TargetValue.string(textControl.id)
            let attrParams = ["v": lengthValue, "hash": textValue]

            if eventType == NIDEventName.input {
                NIDPrintLog("NID keydown field = <\(textControl.id)>")
                let inputTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.input, view: textControl, type: inputType, attrParams: attrParams)
                var inputEvent = NIDEvent(type: NIDEventName.input, tg: inputTG)

                inputEvent.v = lengthValue
                inputEvent.hv = hashValue
                inputEvent.tgs = tgs.toString()

                captureEvent(event: inputEvent)
            } else if eventType == NIDEventName.focus || eventType == NIDEventName.blur {
                // Focus / Blur
                var focusBlurEvent = NIDEvent(type: eventType, tg: [
                    "tgs": tgs,
                ])

                focusBlurEvent.tgs = tgs.toString()

                captureEvent(event: focusBlurEvent)

                // If this is a blur event, that means we have a text change event
                if eventType == NIDEventName.blur {
                    // Text Change
                    let textChangeTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.textChange, view: textControl, type: inputType, attrParams: attrParams)
                    var textChangeEvent = NIDEvent(type: NIDEventName.textChange, tg: textChangeTG, sm: 0, pd: 0)

                    textChangeEvent.v = lengthValue
                    textChangeEvent.hv = hashValue
                    textChangeEvent.tgs = tgs.toString()

//                    textChangeEvent.hv = hashValue
                    captureEvent(event: textChangeEvent)
                    NeuroID.send()
                }
            }

//            detectPasting(view: textControl, text: textControl.text ?? "")
        } else if let textControl = notification.object as? UITextView {
            NeuroIDTracker.registerViewIfNotRegistered(view: textControl)
            let inputType = "text"
            // isSecureText
            if #available(iOS 11.0, *) {
                if textControl.textContentType == .password || textControl.isSecureTextEntry { return }
            }
            if #available(iOS 12.0, *) {
                if textControl.textContentType == .newPassword { return }
            }

            let hashValue = textControl.text?.sha256().prefix(8).string
            let lengthValue = "S~C~~\(textControl.text?.count ?? 0)"
            if eventType == NIDEventName.input {
                NIDPrintLog("NID keydown field = <\(textControl.id)>")

                // Keydown
                let keydownTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.keyDown, view: textControl, type: inputType, attrParams: ["v": lengthValue, "hash": textControl.text ?? ""])
                var keyDownEvent = NIDEvent(type: NIDEventName.keyDown, tg: keydownTG)
                keyDownEvent.v = lengthValue
                keyDownEvent.tgs = TargetValue.string(textControl.id).toString()
//                keyDownEvent.hv = hashValue
                captureEvent(event: keyDownEvent)

                // Text Change
                let textChangeTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.textChange, view: textControl, type: inputType, attrParams: nil)
                var textChangeEvent = NIDEvent(type: NIDEventName.textChange, tg: textChangeTG, sm: 0, pd: 0)
                textChangeEvent.v = lengthValue
                textChangeEvent.hv = hashValue
                textChangeEvent.tgs = TargetValue.string(textControl.id).toString()
                captureEvent(event: textChangeEvent)

                // Input
                let inputTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.input, view: textControl, type: inputType, attrParams: nil)
                var inputEvent = NIDEvent(type: NIDEventName.input, tg: inputTG)
                inputEvent.v = lengthValue
                inputEvent.hv = hashValue
                inputEvent.tgs = TargetValue.string(textControl.id).toString()
                captureEvent(event: inputEvent)
            } else if eventType == NIDEventName.focus || eventType == NIDEventName.blur {
                // Focus / Blur
                var focusBlurEvent = NIDEvent(type: eventType, tg: [
                    "tgs": TargetValue.string(textControl.id),
                ])
                focusBlurEvent.tgs = TargetValue.string(textControl.id).toString()
                captureEvent(event: focusBlurEvent)

                // If this is a blur event, that means we have a text change event
                if eventType == NIDEventName.blur {
                    // Text Change
                    let textChangeTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.textChange, view: textControl, type: inputType, attrParams: nil)
                    var textChangeEvent = NIDEvent(type: NIDEventName.textChange, tg: textChangeTG, sm: 0, pd: 0)
                    textChangeEvent.v = lengthValue
                    textChangeEvent.tgs = TargetValue.string(textControl.id).toString()
//                    textChangeEvent.hv = hashValue
                    captureEvent(event: textChangeEvent)
                }
            }

//            detectPasting(view: textControl, text: textControl.text ?? "")
        } else if let textControl = notification.object as? UISearchBar {
            let tg = ParamsCreator.getTGParamsForInput(eventName: eventType, view: textControl, type: "UISearchBar", attrParams: nil)
            var searchEvent = NIDEvent(type: eventType, tg: tg)
            searchEvent.tgs = TargetValue.string(textControl.id).toString()
            captureEvent(event: searchEvent)
//            detectPasting(view: textControl, text: textControl.text ?? "")
        }
    }

//    func detectPasting(view: UIView, text: String) {
//        var id = "\(Unmanaged.passUnretained(view).toOpaque())"
//        guard var savedText = textCapturing[id] else {
//           return
//        }
//        let savedCount = savedText.count
//        let newCount = text.count
//        if newCount > 0 && newCount - savedCount > 2 {
//            let tg = ParamsCreator.getTextTgParams(
//                view: view,
//                extraParams: ["etn": TargetValue.string(NIDEventName.input.rawValue)])
//            captureEvent(event: NIDEvent(type: .paste, tg: tg, view: view))
//        }
//        textCapturing[id] = text
//    }

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
