//
//  UIControl.swift
//  NeuroID
//
//  Created by Clayton Selby on 8/14/23.
//

import Foundation
import UIKit

import Foundation

class CommonTextFieldUtils {
    static func isSensitiveEntry(for textField: UITextField) -> Bool {
        if #available(iOS 11.0, *) {
            if textField.textContentType == .password || textField.isSecureTextEntry { return true }
        }
        if #available(iOS 12.0, *) {
            if textField.textContentType == .newPassword { return true }
        }

        return false
    }
}
