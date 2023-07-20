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
    func addTapGesture() {
        // Add a single-tap gesture recognizer
        let singleTapGesture = CustomTapGestureRecognizer(target: self, action: #selector(self.handleSingleTap))
        self.addGestureRecognizer(singleTapGesture)

        // Add a double-tap gesture recognizer
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTapGesture)

        // Add a long-press gesture recognizer
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        self.addGestureRecognizer(longPressGesture)

        // Ensure that single-tap gesture is recognized before double-tap gesture
        singleTapGesture.require(toFail: doubleTapGesture)

//        // Ensure that the single-tap gesture is recognized before the long-press gesture
//        singleTapGesture.require(toFail: longPressGesture)
    }

    @objc func handleSingleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)
        captureTouchEvent(type: NIDEventName.click, view: gestureRecognizer.view, location: location)
        self.becomeFirstResponder()
    }

    @objc func handleDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)
        captureTouchEvent(type: NIDEventName.doubleClick, view: gestureRecognizer.view, location: location)
        self.becomeFirstResponder()
    }

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)
        if gestureRecognizer.state == .began {
            captureTouchEvent(type: NIDEventName.longPress, view: gestureRecognizer.view, location: location, extraAttr: ["type": "start"])
        } else if gestureRecognizer.state == .ended {
            captureTouchEvent(type: NIDEventName.longPress, view: gestureRecognizer.view, location: location, extraAttr: ["type": "end"])
        }
        self.becomeFirstResponder()
    }

    @objc static func startSwizzling() {
        let textField = UITextField.self

        textFieldSwizzling(element: textField,
                           originalSelector: #selector(textField.cut(_:)),
                           swizzledSelector: #selector(textField.neuroIDCut))

        textFieldSwizzling(element: textField,
                           originalSelector: #selector(textField.copy(_:)),
                           swizzledSelector: #selector(textField.neuroIDCopy))

        textFieldSwizzling(element: textField,
                           originalSelector: #selector(textField.paste(_:)),
                           swizzledSelector: #selector(textField.neuroIDPaste))
    }

    @objc func neuroIDCut(caller: UIResponder) {
        self.neuroIDCut(caller: caller)
        captureContextMenuAction(type: NIDEventName.cut, view: self, text: text, className: className)
    }

    @objc func neuroIDCopy(caller: UIResponder) {
        self.neuroIDCopy(caller: caller)
        captureContextMenuAction(type: NIDEventName.copy, view: self, text: text, className: className)
    }

    @objc func neuroIDPaste(caller: UIResponder) {
        self.neuroIDPaste(caller: caller)
        captureContextMenuAction(type: NIDEventName.paste, view: self, text: text, className: className)
    }
}
