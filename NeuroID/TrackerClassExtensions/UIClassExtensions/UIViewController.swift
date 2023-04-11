//
//  UIViewController.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

private func registerSubViewsTargets(subViewControllers: [UIViewController]) {
    let filtered = subViewControllers.filter { !$0.ignoreLists.contains($0.className) }
    for ctrls in filtered {
        let screenName = ctrls.className
        NIDPrintLog("Registering view controllers \(screenName)")
        guard let view = ctrls.view else {
            return
        }
        let guid = UUID().uuidString

        NeuroIDTracker.registerSingleView(v: view, screenName: screenName, guid: guid)
        let childViews = ctrls.view.subviewsRecursive()
        for _view in childViews {
            NIDPrintLog("Registering single view.")
            NeuroIDTracker.registerSingleView(v: _view, screenName: screenName, guid: guid)
        }
    }
}

internal func swizzling(viewController: UIViewController.Type,
                        originalSelector: Selector,
                        swizzledSelector: Selector)
{
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
        let tracker = NeuroID.trackers[className] ?? NeuroIDTracker(screen: neuroScreenName, controller: self)
        NeuroID.trackers[className] = tracker
        return tracker
    }

    func captureEvent(event: NIDEvent) {
        if ignoreLists.contains(className) { return }
        var tg: [String: TargetValue] = event.tg ?? [:]
        tg["className"] = TargetValue.string(className)
        tg["title"] = TargetValue.string(title ?? "")

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
        let event: NIDEvent
        if params.isEmptyOrNil {
            event = NIDEvent(type: eventName, view: view)
        } else {
            event = NIDEvent(type: eventName, tg: params, view: view)
        }
        captureEvent(event: event)
    }

//    public func captureEventLogViewWillAppear(params: [String: TargetValue]) {
//        captureEvent(eventName: .windowFocus, params: params)
//    }
//
//    public func captureEventLogViewDidLoad(params: [String: TargetValue]) {
//        captureEvent(eventName: .windowLoad, params: params)
//    }
//
//    public func captureEventLogViewWillDisappear(params: [String: TargetValue]) {
//        captureEvent(eventName: .windowBlur, params: params)
//    }
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

        swizzling(viewController: screen,
                  originalSelector: #selector(screen.viewWillAppear),
                  swizzledSelector: #selector(screen.neuroIDViewWillAppear))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.viewWillDisappear),
                  swizzledSelector: #selector(screen.neuroIDViewWillDisappear))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.viewDidAppear),
                  swizzledSelector: #selector(screen.neuroIDViewDidAppear))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.dismiss),
                  swizzledSelector: #selector(screen.neuroIDDismiss))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.viewDidLayoutSubviews),
                  swizzledSelector: #selector(screen.neuroIDViewDidLayoutSubviews))
    }

    @objc func neuroIDViewWillAppear(animated: Bool) {
        neuroIDViewWillAppear(animated: animated)
        registerViews = nil
    }

    @objc func neuroIDViewWillDisappear(animated: Bool) {
        neuroIDViewWillDisappear(animated: animated)
//        NotificationCenter.default.removeObserver(self)
        registerViews = nil
//        captureEvent(eventName: .windowBlur)
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
//        captureEvent(eventName: .windowFocus)
        var subViews = view.subviews
        var allViewControllers = children
        allViewControllers.append(self)
        registerSubViewsTargets(subViewControllers: allViewControllers)
        registerViews = view.subviewsDescriptions
    }

    @objc func neuroIDDismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        neuroIDDismiss(animated: flag, completion: completion)
    }

    @objc func neuroIDViewDidLayoutSubviews() {
        neuroIDViewDidLayoutSubviews()
        if NeuroID.isStopped() {
            return
        }
        if description.contains(className), let registerViews = registerViews {
//            print("Old Views saved it")
//            registerViews.forEach({ print( "Old : \($0)\n" )})
//            print("Current Views saved it")
//            self.view.subviews.forEach({ print( "Current : \($0.description)\n" )})
//            print("New views to register")
            let newViews = view.subviews.filter { !$0.description.compareDescriptions(registerViews) && !ignoreLists.contains($0.className) }
//            newViews.forEach({ print( "New : \($0.description)\n" )})
//            print("**************************")
            for newView in newViews {
                let screenName = className
                NIDPrintLog("Registering view after load viewController")
                let guid = UUID().uuidString
                NeuroIDTracker.registerSingleView(v: newView, screenName: screenName, guid: guid)
                let childViews = newView.subviewsRecursive()
                for _view in childViews {
                    NIDPrintLog("Registering single subview.")
                    NeuroIDTracker.registerSingleView(v: _view, screenName: screenName, guid: guid)
                }
            }
            self.registerViews = view.subviewsDescriptions
        }
    }
}
