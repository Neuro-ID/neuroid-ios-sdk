//
//  UIView.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

// MARK: - Swizzling

private extension UIView {
    // Add tap recognizer to all views?

//    func test(view: UIView){

//    }
//    @objc static func startSwizzling() {
//        test(self.viewWithTag(self))
    ////        UIView.self.addGestureRecognizer(touchListener)
//    }
//
//    convenience private override init() {
//        print("hi")
//    }
}

/***
 Anytime a view loads
 Check child subviews for eligible form events
 Form all eligible form events, check to see if they have a valid identifier and set one
 Register form events
 */

extension UIView {
    func subviewsRecursive() -> [Any] {
        return subviews + subviews.flatMap { $0.subviewsRecursive() }
    }

    var className: String {
        return String(describing: type(of: self))
    }

    var subviewsDescriptions: [String] {
        return subviews.map { $0.description }
    }
}

public extension UIView {
    var id: String {
        get {
            var title = "UNKNOWN_NO_ID_SET"

            if #available(iOS 13.0, *) {
                title = "UNKNOWN_NO_ID_SET"
                title.replacingOccurrences(of: " ", with: "_")
            } else {
                // Fallback on earlier versions
            }
            title = "\(className)_\(title)"
            var backupName = "\(className)\(description.hashValue)"
            return (accessibilityIdentifier.isEmptyOrNil) ? title : accessibilityIdentifier!
        }
        set {
            accessibilityIdentifier = newValue
        }
    }
}
