//
//  UITextField.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

private func textFieldSwizzling(element: UITextField.Type,
                                originalSelector: Selector,
                                swizzledSelector: Selector)
{
    let originalMethod = class_getInstanceMethod(element, originalSelector)
    let swizzledMethod = class_getInstanceMethod(element, swizzledSelector)

    if let originalMethod = originalMethod,
       let swizzledMethod = swizzledMethod
    {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

internal extension UITextField {
//    func  addTapGesture(){
//        let tap = UITapGestureRecognizer(target: self , action: #selector(self.handleTap(_:)))
//        self.addGestureRecognizer(tap)
//
//    }
//    @objc func handleTap(_ sender: UITapGestureRecognizer) {
//        print("Gesture recognized")
//    }

    @objc static func startSwizzling() {
        let textField = UITextField.self

        textFieldSwizzling(element: textField,
                           originalSelector: #selector(textField.paste(_:)),
                           swizzledSelector: #selector(textField.neuroIDPaste))
    }

    @objc func neuroIDPaste(caller: UIResponder) {
        neuroIDPaste(caller: caller)
        neuroIDPasteUtil(caller: caller, view: self, text: text, className: className)
    }
}
