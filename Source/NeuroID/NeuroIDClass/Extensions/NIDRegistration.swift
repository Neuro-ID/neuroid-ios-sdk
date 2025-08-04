//
//  NIDRegistration.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation
import UIKit

public extension NeuroID {
    static func excludeViewByTestID(_ excludedView: String) {
        logger.i("Exclude view called - \(excludedView)")
        NeuroID.excludedViewsTestIDs.append(excludedView)
    }

    static func excludeViewByTestID(excludedView: String) {
        NeuroID.excludeViewByTestID(excludedView)
    }

    /**
        Specifically available for the React Native SDK to call and register all page targets due to lifecycle event delays
     */
    static func registerPageTargets() {
        if let viewController = UIApplication.shared.keyWindow?.rootViewController {
            DispatchQueue.main.async {
                viewController.registerPageTargets()
            }
        }
    }

    @available(*, deprecated, message: "manuallyRegisterTarget is deprecated and no longer used")
    /** Public API for manually registering a target. This should only be used when automatic fails. */
    static func manuallyRegisterTarget(view: UIView) {
        let screenName = view.id
        let guid = ParamsCreator.generateID()
        logger.d(tag: "\(Constants.registrationTag.rawValue)", "Registering single view: \(screenName)")
        NeuroIDTracker.registerSingleView(
            v: view,
            screenName: screenName,
            guid: guid,
            topDownHierarchyPath: ""
        )
        let childViews = view.subviewsRecursive()

        for _view in childViews {
            logger.d(tag: "\(Constants.registrationTag.rawValue)", "Registering subview Parent: \(screenName) Child: \(_view)")
            NeuroIDTracker.registerSingleView(
                v: _view,
                screenName: screenName,
                guid: guid,
                topDownHierarchyPath: ""
            )
        }
    }

    @available(*, deprecated, message: "manuallyRegisterRNTarget is deprecated and no longer used")
    /** React Native API for manual registration - DEPRECATED */
    static func manuallyRegisterRNTarget(id: String, className: String, screenName: String, placeHolder: String) -> NIDEvent {
        let guid = ParamsCreator.generateID()
        let fullViewString = screenName

        let nidEvent = NIDEvent(type: .registerTarget)
        nidEvent.tgs = id
        nidEvent.eid = id
        nidEvent.en = id
        nidEvent.etn = NIDEventName.input.rawValue
        nidEvent.et = "\(className)"
        nidEvent.ec = screenName
        nidEvent.v = "\(Constants.eventValuePrefix.rawValue)\(placeHolder.count)"
        nidEvent.url = screenName

        nidEvent.hv = placeHolder.hashValue()

        nidEvent.tg = [
            "\(Constants.attrKey.rawValue)": TargetValue.attr([
                Attr(n: "\(Constants.attrScreenHierarchyKey.rawValue)", v: fullViewString),
                Attr(n: "\(Constants.attrGuidKey.rawValue)", v: guid)
            ])
        ]
        nidEvent.attrs = [
            Attrs(n: "\(Constants.attrGuidKey.rawValue)", v: guid),
            Attrs(n: "\(Constants.attrScreenHierarchyKey.rawValue)", v: fullViewString)
        ]

        NeuroID.saveEventToLocalDataStore(nidEvent)
        return nidEvent
    }

    @available(*, deprecated, message: "setCustomVariable is deprecated, use `setVariable` instead")
    static func setCustomVariable(key: String, v: String) -> NIDEvent {
        return self.setVariable(key: key, value: v)
    }

    /**
     Set a variable with a key and value.
        - Parameters:
            - key: The string value of the variable key
            - value: The string value of variable
        - Returns: An `NIDEvent` object of type `SET_VARIABLE`

     */
    static func setVariable(key: String, value: String) -> NIDEvent {
        let variableEvent = NIDEvent(sessionEvent: NIDSessionEventName.setVariable)
        variableEvent.key = key
        variableEvent.v = NeuroID.identifierService.scrubIdentifier(value)

        let myKeys: [String] = trackers.map { String($0.key) }

        // Set the screen to the last active view
        variableEvent.url = myKeys.last

        // If we don't have a valid URL, that means this was called before any views were tracked. Use "AppDelegate" as default
        if variableEvent.url == nil || variableEvent.url!.isEmpty {
            variableEvent.url = "AppDelegate"
        }

        saveEventToLocalDataStore(variableEvent)
        return variableEvent
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
