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
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.popViewController),
                  swizzledSelector: #selector(screen.neuroIDPopViewController(animated:)))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.popToViewController(_:animated:)),
                  swizzledSelector: #selector(screen.neuroIDPopToViewController(_:animated:)))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.popToRootViewController),
                  swizzledSelector: #selector(screen.neuroIDPopToRootViewController))

        swizzling(viewController: screen,
                  originalSelector: #selector(screen.pushViewController(_:animated:)),
                  swizzledSelector: #selector(screen.neuroIDPushViewController(_:animated:)))
    }

    @objc func neuroIDPopViewController(animated: Bool) -> UIViewController? {
        captureWindowEvent(type: .windowUnload, attrs: [
            Attrs(n: "poppedFrom", v: "\(NeuroID.getScreenName() ?? "")"),
            Attrs(n: "popType", v: "singlePop"),
        ])

        return neuroIDPopViewController(animated: animated)
    }

    @objc func neuroIDPopToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        captureWindowEvent(type: .windowUnload, attrs: [
            Attrs(n: "poppedFrom", v: "\(NeuroID.getScreenName() ?? "")"),
            Attrs(n: "popType", v: "specificPop"),
            Attrs(n: "navTitle", v: "\(viewController.navigationItem.title ?? "")"),
        ])

        return neuroIDPopToViewController(viewController, animated: animated)
    }

    @objc func neuroIDPopToRootViewController(animated: Bool) -> [UIViewController]? {
        captureWindowEvent(type: .windowUnload, attrs: [
            Attrs(n: "poppedFrom", v: "\(NeuroID.getScreenName() ?? "")"),
            Attrs(n: "popType", v: "rootPop"),
        ])

        return neuroIDPopToRootViewController(animated: animated)
    }

    @objc func neuroIDPushViewController(_ viewController: UIViewController, animated: Bool) {
        captureWindowEvent(type: .windowLoad, attrs: [
            Attrs(n: "pushedFrom", v: "\(NeuroID.getScreenName() ?? "")"),
            Attrs(n: "navTitle", v: "\(viewController.navigationItem.title ?? "")"),
        ])

        return neuroIDPushViewController(viewController, animated: animated)
    }

    func captureWindowEvent(type: NIDEventName, attrs: [Attrs] = []) {
        let event = NIDEvent(type: type)
        event.attrs = attrs

        captureEvent(event: event)
    }
}
