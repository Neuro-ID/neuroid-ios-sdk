//
//  NIDRegistration.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation
import UIKit

public extension NeuroID {
    static func excludeViewByTestID(excludedView: String) {
        NIDPrintLog("Exclude view called - \(excludedView)")
        NeuroID.excludedViewsTestIDs.append(excludedView)
    }

    /** Public API for manually registering a target. This should only be used when automatic fails. */
    static func manuallyRegisterTarget(view: UIView) {
        let screenName = view.id
        let guid = UUID().uuidString
        NIDPrintLog("Registering single view: \(screenName)")
        NeuroIDTracker.registerSingleView(v: view, screenName: screenName, guid: guid)
        let childViews = view.subviewsRecursive()
        for _view in childViews {
            NIDPrintLog("Registering subview Parent: \(screenName) Child: \(_view)")
            NeuroIDTracker.registerSingleView(v: _view, screenName: screenName, guid: guid)
        }
    }

    /** React Native API for manual registration */
    static func manuallyRegisterRNTarget(id: String, className: String, screenName: String, placeHolder: String) -> NIDEvent {
        let guid = UUID().uuidString
        let fullViewString = UtilFunctions.getFullViewlURLPath(currView: nil, screenName: screenName)
        var nidEvent = NIDEvent(eventName: NIDEventName.registerTarget, tgs: id, en: id, etn: "INPUT", et: "\(className)", ec: screenName, v: "\(Constants.eventValuePrefix.rawValue)\(placeHolder.count)", url: screenName)
        nidEvent.hv = placeHolder.hashValue()
        let attrVal = Attrs(n: "guid", v: guid)
        // Screen hierarchy
        let shVal = Attrs(n: "screenHierarchy", v: fullViewString)
        let guidValue = Attr(n: "guid", v: guid)
        let attrValue = Attr(n: "screenHierarchy", v: fullViewString)
        nidEvent.tg = ["attr": TargetValue.attr([attrValue, guidValue])]
        nidEvent.attrs = [attrVal, shVal]
        NeuroID.saveEventToLocalDataStore(nidEvent)
        return nidEvent
    }

    /**
     Set a custom variable with a key and value.
        - Parameters:
            - key: The string value of the variable key
            - v: The string value of variable
        - Returns: An `NIDEvent` object of type `SET_VARIABLE`

     */
    static func setCustomVariable(key: String, v: String) -> NIDEvent {
        var setCustomVariable = NIDEvent(type: NIDSessionEventName.setVariable, key: key, v: v)
        let myKeys: [String] = trackers.map { String($0.key) }
        // Set the screen to the last active view
        setCustomVariable.url = myKeys.last
        // If we don't have a valid URL, that means this was called before any views were tracked. Use "AppDelegate" as default
        if setCustomVariable.url == nil || setCustomVariable.url!.isEmpty {
            setCustomVariable.url = "AppDelegate"
        }
        saveEventToLocalDataStore(setCustomVariable)
        return setCustomVariable
    }

    internal static func registerKeyboardListener(className: String, view: UIViewController) {
        if !self.observingKeyboard {
            self.observingKeyboard.toggle()

            NotificationCenter.default.addObserver(view, selector: #selector(view.keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(view, selector: #selector(view.keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }

    internal static func removeKeyboardListener(className: String, view: UIViewController) {
        if self.observingKeyboard {
            self.observingKeyboard.toggle()

            NotificationCenter.default.removeObserver(view, name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.removeObserver(view, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }
}
