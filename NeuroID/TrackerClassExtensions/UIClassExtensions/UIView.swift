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
                title = title.replacingOccurrences(of: " ", with: "_")
            }

            title = "\(className)_\(title)"
            var backupName = "\(description.hashValue)"

            var placeholder = ""
            if let textControl = self as? UITextField {
                placeholder = textControl.placeholder ?? ""
            } else if let textControl = self as? UIDatePicker {
                backupName = "\(textControl.hash)"
            } else if let textControl = self as? UIButton {
                backupName = "\(textControl.hash)"
            } else if let textControl = self as? UISlider {
                backupName = "\(textControl.hash)"
            } else if let textControl = self as? UISegmentedControl {
                backupName = "\(textControl.hash)"
            } else if let textControl = self as? UISwitch {
                backupName = "\(textControl.hash)"
            }

            //            print("view access \(accessibilityIdentifier) - \(accessibilityLabel) - end")
            //            print("view ID: \((accessibilityIdentifier.isEmptyOrNil) ? title : accessibilityIdentifier!)")

            return (accessibilityIdentifier.isEmptyOrNil) ? placeholder != "" ? placeholder : "\(title)_\(backupName)" : accessibilityIdentifier!
        }
        set {
            accessibilityIdentifier = newValue
        }
    }
}
