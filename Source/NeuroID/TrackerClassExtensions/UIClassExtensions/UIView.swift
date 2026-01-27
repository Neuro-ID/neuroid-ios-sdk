//
//  UIView.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

/***
 Anytime a view loads
 Check child subviews for eligible form events
 Form all eligible form events, check to see if they have a valid identifier and set one
 Register form events
 */

extension UIView {
    /**
        This attribute will navigate up the elements responder tree until a UIViewController that is responsible for the UIView is found.
     */
    var viewController: UIViewController? {
        var responder: UIResponder? = self
        while let currentResponder = responder {
            responder = currentResponder.next
            if let viewController = currentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }

    func subviewsRecursive() -> [Any] {
        return subviews + subviews.flatMap { $0.subviewsRecursive() }
    }

    var nidClassName: String {
        return String(describing: type(of: self))
    }

    var subviewsDescriptions: [String] {
        return subviews.map { $0.description }
    }
}

public extension UIView {
    var id: String {
        get {
            let title = "\(nidClassName)_UNKNOWN_NO_ID_SET"
            var backupName = "\(description.hashValue)"

            var placeholder = ""
            if let textControl = self as? UITextField {
                placeholder = textControl.placeholder ?? ""
            } else if let textControl = self as? UIDatePicker {
                backupName = "\(textControl.hash)"
            } else if let textControl = self as? UIButton {
                backupName = "\(textControl.titleLabel?.text ?? "")-\(textControl.hash)"
            } else if let textControl = self as? UISlider {
                backupName = "\(textControl.hash)"
            } else if let textControl = self as? UISegmentedControl {
                backupName = "\(textControl.hash)"
            } else if let textControl = self as? UISwitch {
                backupName = "\(textControl.hash)"
            }

            return (accessibilityIdentifier.isEmptyOrNil) ? placeholder != "" ? placeholder : "\(title)_\(backupName)" : accessibilityIdentifier!
        }
        set {
            accessibilityIdentifier = newValue
        }
    }
}
