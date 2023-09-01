//
//  UIViewController.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

internal func uiViewSwizzling(
    viewController: UIViewController.Type,
    originalSelector: Selector,
    swizzledSelector: Selector
) {
    let originalMethod = class_getInstanceMethod(viewController, originalSelector)
    let swizzledMethod = class_getInstanceMethod(viewController, swizzledSelector)

    if let originalMethod = originalMethod,
       let swizzledMethod = swizzledMethod
    {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

public extension UIViewController {
    internal var ignoreLists: [String] {
        return [
            "UICompatibilityInputViewController",
            "UISystemKeyboardDockController",
            "UIInputWindowController",
            "UIPredictionViewController",
            "UIEditingOverlayViewController",
            "UISystemInputAssistantViewController",
            "UIKBVisualEffectView",
            "TUISystemInputAssistantPageView",
            "UIKeyboardAutomatic",
            "UIKeyboardImpl",
            "TUIKeyboardPathEffectView",
            "UIInputSetHostView",
            "UIKBKeyView",
            "UIKeyboardDockItemButton",
            "UIEditingOverlayGestureView",
        ]
    }

    @objc internal var neuroScreenName: String {
        return className
    }

    var tracker: NeuroIDTracker? {
        if ignoreLists.contains(className) { return nil }
        if self is UINavigationController, className == "UINavigationController" { return nil }
        if let tracker = NeuroID.trackers[className] {
            tracker.subscribe(inScreen: self)
            return tracker
        } else {
            let tracker = NeuroID.trackers[className] ?? NeuroIDTracker(screen: neuroScreenName, controller: self)
            NeuroID.trackers[className] = tracker
            return tracker
        }
    }

    func captureEvent(event: NIDEvent) {
        if ignoreLists.contains(className) { return }

        // TODO: Implement UIAlertController
//        if let vc = self as? UIAlertController {
//            tg["message"] = TargetValue.string(vc.message ?? "")
//            tg["actions"] = TargetValue.string(vc.actions.compactMap { $0.title }
//        }
//
//        if let eventName = NIDEventName(rawValue: event.type) {
//            let newEvent = NIDEvent(type: eventName, tg: tg, x: event.x, y: event.y)
//            tracker?.captureEvent(event: newEvent)
//        } else {
//            let newEvent = NIDEvent(customEvent: event.type, tg: tg, x: event.x, y: event.y)
        tracker?.captureEvent(event: event)
//        }
    }

    func captureEvent(eventName: NIDEventName, params: [String: TargetValue]? = nil) {
        let event = NIDEvent(type: eventName, tg: params, view: view)

        captureEvent(event: event)
    }
}

extension UIViewController {
    var className: String {
        return String(describing: type(of: self))
    }
}

internal extension UIViewController {
    private var registerViews: [String]? {
        get {
            return UserDefaults(suiteName: "ViewHierarchy")?.object(forKey: "registerViews") as? [String]
        }
        set {
            UserDefaults(suiteName: "ViewHierarchy")?.set(newValue, forKey: "registerViews")
        }
    }

    @objc static func startSwizzling() {
        let screen = UIViewController.self

        uiViewSwizzling(viewController: screen,
                        originalSelector: #selector(screen.viewWillAppear),
                        swizzledSelector: #selector(screen.neuroIDViewWillAppear))
        uiViewSwizzling(viewController: screen,
                        originalSelector: #selector(screen.viewWillDisappear),
                        swizzledSelector: #selector(screen.neuroIDViewWillDisappear))
        uiViewSwizzling(viewController: screen,
                        originalSelector: #selector(screen.viewDidAppear),
                        swizzledSelector: #selector(screen.neuroIDViewDidAppear))
        uiViewSwizzling(viewController: screen,
                        originalSelector: #selector(screen.dismiss),
                        swizzledSelector: #selector(screen.neuroIDDismiss))
        uiViewSwizzling(viewController: screen,
                        originalSelector: #selector(screen.viewDidDisappear),
                        swizzledSelector: #selector(screen.neuroIDViewDidDisappear))
    }

    @objc func neuroIDViewWillAppear(animated: Bool) {
        neuroIDViewWillAppear(animated: animated)
        registerViews = nil
    }

    @objc func neuroIDViewWillDisappear(animated: Bool) {
        neuroIDViewWillDisappear(animated: animated)
        registerViews = nil
    }

    /**
        When overriding viewDidLoad in  controllers make sure that super is the last thing called in the function (so that we can accurately detect all added views/subviews)

          Anytime a view loads
          Check child subviews for eligible form events
          Form all eligible form events, check to see if they have a valid identifier and set one
          Register form events
     */
    @objc func neuroIDViewDidAppear() {
        neuroIDViewDidAppear()

        if NeuroID.isStopped() {
            return
        }

        // We need to init the tracker on the views.
        tracker
//        let subViews = view.subviews
        var allViewControllers = children
        allViewControllers.append(self)
        UtilFunctions.registerSubViewsTargets(subViewControllers: allViewControllers)
        registerViews = view.subviewsDescriptions

        NeuroID.registerKeyboardListener(className: className, view: self)

        UtilFunctions.captureWindowLoadUnloadEvent(eventType: .windowLoad, id: hash.string, className: className)
    }

    @objc func neuroIDViewDidDisappear() {
        neuroIDViewDidDisappear()

        UtilFunctions.captureWindowLoadUnloadEvent(eventType: .windowUnload, id: hash.string, className: className)
    }

    @objc func neuroIDDismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        neuroIDDismiss(animated: flag, completion: completion)
        NeuroID.removeKeyboardListener(className: className, view: self)
    }

    @objc func keyboardWillShow(notification: Notification) {
        // Handle keyboard will show event - potentially fires twice (might be a simulator bug)
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            // Determine the safe area insets of the device
            var safeAreaInsets: UIEdgeInsets = .zero
            if #available(iOS 11.0, *) {
                safeAreaInsets = view.safeAreaInsets
            }

            // Compare the bottom of the keyboard frame with the bottom of the screen
            let keyboardBottomY = keyboardFrame.origin.y + keyboardFrame.size.height
            let screenBottomY = UIScreen.main.bounds.size.height - safeAreaInsets.bottom
            var inSafeArea = false
            if keyboardBottomY <= screenBottomY {
                inSafeArea = true
            }

            if NeuroID.isStopped() {
                return
            }

            let event = NIDEvent(type: NIDEventName.windowResize)

            event.w = UIScreen.main.bounds.size.width
            event.h = UIScreen.main.bounds.size.height - keyboardFrame.size.height
            event.x = keyboardFrame.origin.x
            event.y = keyboardFrame.origin.y
            event.tgs = view.id
            event.attrs = [
                Attrs(n: "inSafeArea", v: "\(inSafeArea)"),
                Attrs(n: "appear", v: "\(true)"),

                Attrs(n: "keyboardW", v: "\(keyboardFrame.size.width)"),
                Attrs(n: "keyboardH", v: "\(keyboardFrame.size.height)"),
                Attrs(n: "keyboardX", v: "\(keyboardFrame.origin.x)"),
                Attrs(n: "keyboardY", v: "\(keyboardFrame.origin.y)"),
                Attrs(n: "screenHeightTotal", v: "\(UIScreen.main.bounds.size.height)"),
                Attrs(n: "screenWidthTotal", v: "\(UIScreen.main.bounds.size.width)"),
            ]

            // Make sure we have a valid url set
            event.url = className
            DataStore.insertEvent(screen: className, event: event)
        }
    }

    @objc func keyboardWillHide(notification: Notification) {
        // Handle keyboard will hide event - Does not recieve any X, Y, W, H information

        let event = NIDEvent(type: NIDEventName.windowResize)

        event.w = UIScreen.main.bounds.size.width
        event.h = UIScreen.main.bounds.size.height
        event.tgs = view.id
        event.attrs = [
            Attrs(n: "appear", v: "\(false)"),
        ]

        // Make sure we have a valid url set
        event.url = className
        DataStore.insertEvent(screen: className, event: event)
    }
}
