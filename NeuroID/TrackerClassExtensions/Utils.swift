//
//  Utils.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/30/23.
//

import Foundation
import UIKit

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

    static func registerSubViewsTargets(subViewControllers: [UIViewController]) {
        let filtered = subViewControllers.filter { !$0.ignoreLists.contains($0.className) }
        for ctrls in filtered {
            let screenName = ctrls.className
            NIDDebugPrint(tag: "\(Constants.registrationTag.rawValue)", "Registering view controllers \(screenName)")
            guard let view = ctrls.view else {
                return
            }
            let guid = UUID().uuidString

            NeuroIDTracker.registerSingleView(v: view, screenName: screenName, guid: guid)
            let childViews = ctrls.view.subviewsRecursive()
            for _view in childViews {
                NIDDebugPrint(tag: "\(Constants.registrationTag.rawValue)", "Registering single view.")
                NeuroIDTracker.registerSingleView(v: _view, screenName: screenName, guid: guid)
            }
        }
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

        let nidEvent = NIDEvent(type: .registerTarget)
        nidEvent.tgs = id
        nidEvent.eid = id
        nidEvent.en = id
        nidEvent.etn = etn
        nidEvent.et = "\(type)::\(className)"
        nidEvent.ec = screenName
        nidEvent.v = rawText ?? false ? textValue : "\(Constants.eventValuePrefix.rawValue)\(textValue.count)"
        nidEvent.url = screenName

        nidEvent.hv = textValue.hashValue()
        nidEvent.tg = tg
        nidEvent.attrs = attrs

        // If RTS is set, set rts on focus events
        nidEvent.setRTS(rts)

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
            attrParams: ["\(Constants.vKey.rawValue)": lengthValue, "\(Constants.hashKey.rawValue)": text ?? ""]
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
        let attrParams = ["\(Constants.vKey.rawValue)": lengthValue, "\(Constants.hashKey.rawValue)": textValue]

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
    }

    static func captureFocusBlurEvent(
        eventType: NIDEventName,
        id: String
    ) {
        let event = NIDEvent(
            type: eventType,
            tg: [
                "\(Constants.tgsKey.rawValue)": TargetValue.string(id),
            ]
        )

        event.tgs = id

        NeuroID.saveEventToLocalDataStore(event)

        // URL capture?
    }

    static func captureWindowLoadUnloadEvent(
        eventType: NIDEventName,
        id: String,
        className: String
    ) {
        let event = NIDEvent(
            type: eventType,
            tg: [
                "\(Constants.tgsKey.rawValue)": TargetValue.string(id),
            ]
        )

        event.attrs = [
            Attrs(n: "className", v: className),
        ]
        event.tgs = id

        NeuroID.saveEventToLocalDataStore(event)

        // URL capture?
    }
}
