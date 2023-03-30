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
                  originalSelector: #selector(screen.popViewController(animated:)),
                  swizzledSelector: #selector(screen.neuroIDPopViewController(animated:)))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.popToViewController(_:animated:)),
                  swizzledSelector: #selector(screen.neuroIDPopToViewController(_:animated:)))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.popToRootViewController),
                  swizzledSelector: #selector(screen.neuroIDPopToRootViewController))
    }

    @objc func neuroIDPopViewController(animated: Bool) -> UIViewController? {
        captureEvent(eventName: .windowUnload)
        return neuroIDPopViewController(animated: animated)
    }

    @objc func neuroIDPopToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        captureEvent(eventName: .windowUnload)
        return neuroIDPopToViewController(viewController, animated: animated)
    }

    @objc func neuroIDPopToRootViewController(animated: Bool) -> [UIViewController]? {
        captureEvent(eventName: .windowUnload)
        return neuroIDPopToRootViewController(animated: animated)
    }
}
