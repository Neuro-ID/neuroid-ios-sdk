//
//  NIDRegistration.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation
import UIKit

extension NeuroID {
    func excludeViewByTestID(_ excludedView: String) {
        NIDLog.i("Exclude view called - \(excludedView)")
        self.excludedViewsTestIDs.append(excludedView)
    }

    func excludeViewByTestID(excludedView: String) {
        self.excludeViewByTestID(excludedView)
    }

    /**
        Specifically available for the React Native SDK to call and register all page targets due to lifecycle event delays
     */
    func registerPageTargets() {
        if let viewController = UIApplication.shared.keyWindow?.rootViewController {
            DispatchQueue.main.async {
                viewController.registerPageTargets()
            }
        }
    }

    func manuallyRegisterTarget(view: UIView) {
        let screenName = view.id
        let guid = ParamsCreator.generateID()
        NIDLog.d("\(Constants.registrationTag.rawValue) Registering single view: \(screenName)")
        NeuroIDTracker.registerSingleView(
            v: view,
            screenName: screenName,
            guid: guid,
            topDownHierarchyPath: ""
        )
        let childViews = view.subviewsRecursive()

        for _view in childViews {
            NIDLog.d("\(Constants.registrationTag.rawValue) Registering subview Parent: \(screenName) Child: \(_view)")
            NeuroIDTracker.registerSingleView(
                v: _view,
                screenName: screenName,
                guid: guid,
                topDownHierarchyPath: ""
            )
        }
    }

    func manuallyRegisterRNTarget(
        id: String,
        className: String,
        screenName: String,
        placeHolder: String
    ) -> NIDEvent {
        let guid = ParamsCreator.generateID()
        let fullViewString = screenName

        let nidEvent = NIDEvent(type: .registerTarget,
                                tg: [
                                    "\(Constants.attrKey.rawValue)": TargetValue.attr([
                                        Attr(n: "\(Constants.attrScreenHierarchyKey.rawValue)", v: fullViewString),
                                        Attr(n: "\(Constants.attrGuidKey.rawValue)", v: guid)
                                    ])
                                ],
                                tgs: id,
                                v: "\(Constants.eventValuePrefix.rawValue)\(placeHolder.count)",
                                hv: placeHolder.hashValue(),
                                en: id,
                                etn: NIDEventName.input.rawValue,
                                et: "\(className)",
                                ec: screenName,
                                eid: id,
                                url: screenName,
                                attrs: [
                                    Attrs(n: "\(Constants.attrGuidKey.rawValue)", v: guid),
                                    Attrs(
                                        n: "\(Constants.attrScreenHierarchyKey.rawValue)", v: fullViewString
                                    )
                                ])

        self.saveEventToLocalDataStore(nidEvent)
        return nidEvent
    }

    @available(*, deprecated, message: "setCustomVariable is deprecated, use `setVariable` instead")
    func setCustomVariable(key: String, v: String) -> NIDEvent {
        return self.setVariable(key: key, value: v)
    }

    /**
     Set a variable with a key and value.
        - Parameters:
            - key: The string value of the variable key
            - value: The string value of variable
        - Returns: An `NIDEvent` object of type `SET_VARIABLE`

     */
    func setVariable(key: String, value: String) -> NIDEvent {
        let myKeys: [String] = NeuroID.trackers.map { String($0.key) }

        // If we don't have a valid URL, that means this was called before any views were tracked. Use "AppDelegate" as default
        var url = myKeys.last
        if url == nil || url!.isEmpty {
            url = "AppDelegate"
        }

        let variableEvent = NIDEvent(
            type: .setVariable,
            key: key,
            v: NeuroID.shared.identifierService.scrubIdentifier(value),
            url: url
        )

        self.saveEventToLocalDataStore(variableEvent)
        return variableEvent
    }

     func registerKeyboardListener(className: String, view: UIViewController) {
        if !self.observingKeyboard {
            self.observingKeyboard.toggle()

            NotificationCenter.default.addObserver(view, selector: #selector(view.keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(view, selector: #selector(view.keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }

     func removeKeyboardListener(className: String, view: UIViewController) {
        if self.observingKeyboard {
            self.observingKeyboard.toggle()

            NotificationCenter.default.removeObserver(view, name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.removeObserver(view, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }
}
