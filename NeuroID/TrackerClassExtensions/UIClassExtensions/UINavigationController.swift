//
//  UINavigationController.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

internal extension UINavigationController {
    static func swizzleNavigation() {
        let screen = UINavigationController.self
        uiViewSwizzling(viewController: screen,
                        originalSelector: #selector(screen.popViewController),
                        swizzledSelector: #selector(screen.neuroIDPopViewController(animated:)))
        uiViewSwizzling(viewController: screen,
                        originalSelector: #selector(screen.popToViewController(_:animated:)),
                        swizzledSelector: #selector(screen.neuroIDPopToViewController(_:animated:)))
        uiViewSwizzling(viewController: screen,
                        originalSelector: #selector(screen.popToRootViewController),
                        swizzledSelector: #selector(screen.neuroIDPopToRootViewController))

        uiViewSwizzling(viewController: screen,
                        originalSelector: #selector(screen.pushViewController(_:animated:)),
                        swizzledSelector: #selector(screen.neuroIDPushViewController(_:animated:)))
    }

    @objc func neuroIDPopViewController(animated: Bool) -> UIViewController? {
        captureWindowEvent(type: .navControllerPop, attrs: [
            Attrs(n: "poppedFrom", v: "\(NeuroID.getScreenName() ?? "")"),
            Attrs(n: "popType", v: "singlePop"),
            Attrs(n: "captureMethod", v: "swizzle"),
        ])

        return neuroIDPopViewController(animated: animated)
    }

    @objc func neuroIDPopToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        captureWindowEvent(type: .navControllerPop, attrs: [
            Attrs(n: "poppedFrom", v: "\(NeuroID.getScreenName() ?? "")"),
            Attrs(n: "popType", v: "specificPop"),
            Attrs(n: "navTitle", v: "\(viewController.navigationItem.title ?? "")"),
            Attrs(n: "captureMethod", v: "swizzle"),
        ])

        return neuroIDPopToViewController(viewController, animated: animated)
    }

    @objc func neuroIDPopToRootViewController(animated: Bool) -> [UIViewController]? {
        captureWindowEvent(type: .navControllerPop, attrs: [
            Attrs(n: "poppedFrom", v: "\(NeuroID.getScreenName() ?? "")"),
            Attrs(n: "popType", v: "rootPop"),
            Attrs(n: "captureMethod", v: "swizzle"),
        ])

        return neuroIDPopToRootViewController(animated: animated)
    }

    @objc func neuroIDPushViewController(_ viewController: UIViewController, animated: Bool) {
        captureWindowEvent(type: .navControllerPush, attrs: [
            Attrs(n: "pushedFrom", v: "\(NeuroID.getScreenName() ?? "")"),
            Attrs(n: "navTitle", v: "\(viewController.navigationItem.title ?? "")"),
            Attrs(n: "captureMethod", v: "swizzle"),
        ])

        return neuroIDPushViewController(viewController, animated: animated)
    }

    func captureWindowEvent(type: NIDEventName, attrs: [Attrs] = []) {
        let event = NIDEvent(type: type)
        event.attrs = attrs

        captureEvent(event: event)
    }
}
