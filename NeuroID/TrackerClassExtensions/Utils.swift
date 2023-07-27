//
//  Utils.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/30/23.
//

import Foundation
import UIKit

/***
 Anytime a view loads
 Check child subviews for eligible form events
 Form all eligible form events, check to see if they have a valid identifier and set one
 Register form events
 */
// STILL NEEDED?
internal func getParentClasses(currView: UIView?, hierarchyString: String?) -> String? {
    var newHieraString = "\(currView?.className ?? "UIView")"

    if hierarchyString != nil {
        newHieraString = "\(newHieraString)\\\(hierarchyString!)"
    }

    if currView?.superview != nil {
        return getParentClasses(currView: currView?.superview, hierarchyString: newHieraString)
    }
    return newHieraString
}

internal enum UtilFunctions {
    static func getFullViewlURLPath(currView: UIView?, screenName: String) -> String {
        if currView == nil {
            return screenName
        }
        let parentView = currView!.superview?.className
        let grandParentView = currView!.superview?.superview?.className
        var fullViewString = ""
        if grandParentView != nil {
            fullViewString += "\(grandParentView ?? "")/"
            fullViewString += "\(parentView ?? "")/"
        } else if parentView != nil {
            fullViewString = "\(parentView ?? "")/"
        }
        fullViewString += screenName
        return fullViewString
    }

    static func registerField(
        textValue: String,
        etn: String = "INPUT",
        id: String,
        className: String,
        type: String,
        screenName: String,
        tg: [String: TargetValue],
        attrs: [Attrs],
        rts: Bool? = false,
        rawText: Bool? = false
    ) {
        NeuroID.registeredTargets.append(id)

        //    let temp = getParentClasses(currView: currView, hierarchyString: "UITextField")

        let nidEvent = NIDEvent(
            eventName: NIDEventName.registerTarget,
            tgs: id,
            en: id,
            etn: etn,
            et: "\(type)::\(className)",
            ec: screenName,
            v: rawText ?? false ? textValue : "\(Constants.eventValuePrefix.rawValue)\(textValue.count)",
            url: screenName
        )

        // If RTS is set, set rts on focus events
        nidEvent.setRTS(rts)

        nidEvent.hv = textValue.hashValue()
        nidEvent.tg = tg
        nidEvent.attrs = attrs

        NeuroID.saveEventToLocalDataStore(nidEvent)

        NIDDebugPrint("*****************   Actually Registered View: \(className) - \(id)")
    }

    static func captureContextMenuAction(
        type: NIDEventName,
        view: UIView,
        text: String?,
        className: String?
    ) {
        if NeuroID.isStopped() {
            return
        }

        let lengthValue = "\(Constants.eventValuePrefix.rawValue)\(text?.count ?? 0)"
        let hashValue = text?.hashValue() ?? ""
        let eventTg = ParamsCreator.getTGParamsForInput(
            eventName: type,
            view: view,
            type: type.rawValue,
            attrParams: ["v": lengthValue, "hash": text ?? ""]
        )

        let event = NIDEvent(type: type, tg: eventTg)

        event.v = lengthValue
        event.hv = hashValue
        event.tgs = view.id

        let screenName = className ?? UUID().uuidString
        // Make sure we have a valid url set
        event.url = screenName
        DataStore.insertEvent(screen: screenName, event: event)
    }

    static func captureTextEvents(view: UIView, textValue: String, eventType: NIDEventName) {
        let id = view.id
        let inputType = "text"
        let textValue = textValue
        let lengthValue = "\(Constants.eventValuePrefix.rawValue)\(textValue.count)"
        let hashValue = textValue.hashValue()
        let attrParams = ["v": lengthValue, "hash": textValue]

        switch eventType {
            case .input:
                captureInputTextChangeEvent(
                    eventType: NIDEventName.input,
                    textControl: view,
                    inputType: inputType,
                    lengthValue: lengthValue,
                    hashValue: hashValue,
                    attrParams: attrParams
                )
            case .focus:
                captureFocusBlurEvent(eventType: eventType, id: id)
            case .blur:
                captureFocusBlurEvent(eventType: eventType, id: id)

                captureInputTextChangeEvent(
                    eventType: NIDEventName.textChange,
                    textControl: view,
                    inputType: inputType,
                    lengthValue: lengthValue,
                    hashValue: hashValue,
                    attrParams: attrParams
                )

                NeuroID.send()
            default:
                return
        }
    }

    static func captureInputTextChangeEvent(
        eventType: NIDEventName,
        textControl: UIView,
        inputType: String,
        lengthValue: String,
        hashValue: String,
        attrParams: [String: String]
    ) {
        NIDDebugPrint("NID Input = <\(textControl.id)>")
        let eventTg = ParamsCreator.getTGParamsForInput(
            eventName: eventType,
            view: textControl,
            type: inputType,
            attrParams: attrParams
        )
        let event = NIDEvent(type: eventType, tg: eventTg)

        event.v = lengthValue
        event.hv = hashValue
        event.tgs = textControl.id

        if eventType == .textChange {
            event.sm = 0
            event.pd = 0
        }

        NeuroID.saveEventToLocalDataStore(event)

        // URL capture?
//        captureEvent(event: inputEvent)
    }

    static func captureFocusBlurEvent(
        eventType: NIDEventName,
        id: String
    ) {
        let event = NIDEvent(
            type: eventType,
            tg: [
                "tgs": TargetValue.string(id),
            ]
        )

        event.tgs = id

        NeuroID.saveEventToLocalDataStore(event)

        // URL capture?
//        captureEvent(event: inputEvent)
    }

    static func captureWindowLoadUnloadEvent(
        eventType: NIDEventName,
        id: String,
        className: String
    ) {
        let event = NIDEvent(
            type: eventType,
            tg: [
                "tgs": TargetValue.string(id),
            ]
        )

        event.attrs = [
            Attrs(n: "className", v: className),
        ]
        event.tgs = id

        NeuroID.saveEventToLocalDataStore(event)

        // URL capture?
//        captureEvent(event: inputEvent)
    }
}
