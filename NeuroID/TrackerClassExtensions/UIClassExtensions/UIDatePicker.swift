//
//  UIDatePicker.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/30/23.
//

import Foundation
import UIKit

// private func textFieldSwizzling(element: UITextField.Type,
//                                originalSelector: Selector,
//                                swizzledSelector: Selector)
// {
//    let originalMethod = class_getInstanceMethod(element, originalSelector)
//    let swizzledMethod = class_getInstanceMethod(element, swizzledSelector)
//
//    if let originalMethod = originalMethod,
//       let swizzledMethod = swizzledMethod
//    {
//        method_exchangeImplementations(originalMethod, swizzledMethod)
//    }
// }
//
// internal extension UIDatePicker {
//    @objc static func startSwizzling() {
//        let datefield = UIDatePicker.self
//
//        textFieldSwizzling(element: datefield,
//                           originalSelector: #selector(datefield.didChangeValue),
//                           swizzledSelector: #selector(datefield.neuroIDPaste))
//    }
//
//    func textFieldSwizzling() {}
// }
