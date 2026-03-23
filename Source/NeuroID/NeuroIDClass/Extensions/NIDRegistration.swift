//
//  NIDRegistration.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation
import UIKit

extension NeuroIDCore {
    func excludeViewByTestID(_ excludedView: String) {
        NIDLog.info("Exclude view called - \(excludedView)")
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

    /**
     Set a variable with a key and value.
        - Parameters:
            - key: The string value of the variable key
            - value: The string value of variable
        - Returns: An `NIDEvent` object of type `SET_VARIABLE`

     */
    func setVariable(key: String, value: String) -> NIDEvent {
        let myKeys: [String] = NeuroIDCore.trackers.map { String($0.key) }

        // If we don't have a valid URL, that means this was called before any views were tracked. Use "AppDelegate" as default
        var url = myKeys.last
        if url == nil || url!.isEmpty {
            url = "AppDelegate"
        }

        let variableEvent = NIDEvent(
            type: .setVariable,
            key: key,
            v: NeuroIDCore.shared.identifierService.scrubIdentifier(value),
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
