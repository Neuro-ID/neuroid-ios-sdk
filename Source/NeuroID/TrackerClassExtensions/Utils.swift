//
//  Utils.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/30/23.
//

import Foundation
import UIKit

enum UtilFunctions {
    static func getFutureTimeStamp(_ secondsToAdd: Int) -> Int {
        // Get the current time
        let currentTime = Date()

        // Create a Calendar object
        let calendar = Calendar.current

        // Add the specified number of hours to the current time
        if let futureTime = calendar.date(byAdding: .second, value: secondsToAdd, to: currentTime) {
            return Int(futureTime.timeIntervalSince1970)
        } else {
            return 0
        }
    }

    static func getParentRecursively(viewController: UIViewController) -> [String] {
        if let parent = viewController.parent {
            return [parent.nidClassName] + getParentRecursively(viewController: parent)
        } else {
            return []
        }
    }

    /**
        This method will take the UIView and navigate back through its entire ancestory tree to produce
        a path from the highest UIViewController down to the element.
     */
    static func getFullViewlURLPath(currView: UIView) -> String {
        let viewControllerParent = currView.viewController

        var viewControllerAncestors: [String] = []
        if let parent = viewControllerParent {
            viewControllerAncestors.append(parent.nidClassName)
            viewControllerAncestors = viewControllerAncestors + getParentRecursively(viewController: parent)
        }
        viewControllerAncestors.reverse()

        var finalPath = ""
        for vc in viewControllerAncestors {
            finalPath += "/\(vc)"
        }

        return "\(finalPath)/\(currView.nidClassName)"
    }

    static func registerRecursiveUIViewController(controller: UIViewController, parentTag: String) -> [(UIViewController, String)] {
        var list: [(UIViewController, String)] = []

        let shouldIgnore = controller.ignoreLists.contains(controller.nidClassName)

        if controller.children.isEmpty {
            list.append(
                (
                    controller,
                    "\(controller.nidClassName)"
                )
            )
        }

        for c in controller.children {
            // Append the current element in the list
            list.append(
                (
                    c,
                    "\(parentTag)/\(c.nidClassName)"
                )
            )

            // If the current element is a UIViewController then get all its children
            if !c.children.isEmpty {
                list = list + registerRecursiveUIViewController(controller: c, parentTag: "\(parentTag)/\(c.nidClassName)")
            }
        }

        return list
    }

    static func registerSubViewsTargets(controller: UIViewController) {
        // self
        NIDLog.d(tag: "\(Constants.registrationTag.rawValue)", "Registering Top Level UIViewController \(controller.nidClassName)")

        let allChildren = registerRecursiveUIViewController(controller: controller, parentTag: controller.nidClassName)

        for childController in allChildren {
            // uiNav1 and uiNav2

            // NOTE: This will ignore the controller but its children will still be allowed to be registered
            let shouldIgnore = childController.0.ignoreLists.contains(childController.0.nidClassName)

            if shouldIgnore {
                continue
            }

            NIDLog.d(tag: "\(Constants.registrationTag.rawValue)", "    Registering Child UIViewController \(childController.1) - \(childController.0.nidClassName)")

            guard let view = childController.0.viewIfLoaded else {
                continue
            }
            let screenName = childController.0.nidClassName
            let guid = ParamsCreator.generateID()

            let subViewChildren = view.subviewsRecursive()

            for _view in subViewChildren {
                let v = _view as! UIView
                NIDLog.d(tag: "\(Constants.registrationTag.rawValue)", "         Registering Single View \(childController.1)/\(v.nidClassName)")

                NeuroIDTracker.registerSingleView(
                    v: _view,
                    screenName: screenName,
                    guid: guid,
                    topDownHierarchyPath: "\(childController.1)/\(v.nidClassName)"
                )
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

        NIDLog.d(tag: "\(Constants.registrationTag.rawValue)", "            Registered View: \(className) - \(id)")
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

        let screenName = className ?? ParamsCreator.generateID()
        // Make sure we have a valid url set
        event.url = screenName
        
        NeuroID.saveEventToLocalDataStore(event, screen: screenName)
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
        NIDLog.d("Input = <\(textControl.id)>")
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

    static func captureCallStatusEvent(
        eventType: NIDEventName,
        status: String,
        attrs: [Attrs]
    ) {
        let event = NIDEvent(type: eventType)
        event.cp = status
        event.attrs = attrs
        NeuroID.saveEventToLocalDataStore(event)
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

    static func extractTouchesFromEvent(uiView: UIView, event: UIEvent) -> [NIDTouches] {
        if let touches = event.allTouches {
            return extractTouchInfoFromTouchArray(touches)
        } else {
            return []
        }
    }

    static func extractTouchInfoFromTouchArray(_ touches: Set<UITouch>) -> [NIDTouches] {
        var touchArray: [NIDTouches] = []

        // Loop through each view in the array
        for (index, touch) in touches.enumerated() {
            let touchCor = touch.location(in: nil)
            touchArray.append(
                NIDTouches(
                    x: touchCor.x,
                    y: touchCor.y,
                    tid: index,
                    force: touch.force,
                    majorRadius: touch.majorRadius,
                    phase: touch.phase.rawValue,
                    majorRadiusTolerance: touch.majorRadiusTolerance,
                    tapCount: touch.tapCount,
                    type: touch.type.rawValue,
                    preciseLocation: touch.preciseLocation(in: nil)
                )
            )
        }
        return touchArray
    }

    static func extractTouchesFromGestureRecognizer(
        gestureRecognizer: UIGestureRecognizer
    ) -> [NIDTouches] {
        let touchCount = gestureRecognizer.numberOfTouches

        var touchArray: [NIDTouches] = []
        var uiTouchArray: [NIDTouches] = []

        if touchCount >= 1 {
            for touchIndex in 0 ... touchCount - 1 {
                let touchCor = gestureRecognizer.location(ofTouch: touchIndex, in: nil)

                let uiTouchCor = gestureRecognizer.location(ofTouch: touchIndex, in: gestureRecognizer.view)

                touchArray.append(NIDTouches(x: touchCor.x, y: touchCor.y, tid: touchIndex))
                uiTouchArray.append(NIDTouches(x: uiTouchCor.x, y: uiTouchCor.y, tid: touchIndex))
            }
        }

        return touchArray
    }
}
