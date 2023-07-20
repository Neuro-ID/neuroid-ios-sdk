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
        self.captureTouchInfo(gestureRecognizer: gestureRecognizer, type: NIDEventName.click)
        self.becomeFirstResponder()
    }

    @objc func handleDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        self.captureTouchInfo(gestureRecognizer: gestureRecognizer, type: NIDEventName.doubleClick)
        self.becomeFirstResponder()
    }

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            self.captureLongTouchInfo(gestureRecognizer: gestureRecognizer, type: NIDEventName.longPress, beginEndType: "start")
        } else if gestureRecognizer.state == .ended {
            self.captureLongTouchInfo(gestureRecognizer: gestureRecognizer, type: NIDEventName.longPress, beginEndType: "end")
        }
        self.becomeFirstResponder()
    }

    @objc static func startSwizzling() {
        let textField = UITextField.self

        textFieldSwizzling(element: textField,
                           originalSelector: #selector(textField.paste(_:)),
                           swizzledSelector: #selector(textField.neuroIDPaste))
    }

    @objc func neuroIDPaste(caller: UIResponder) {
        self.neuroIDPaste(caller: caller)
        neuroIDPasteUtil(caller: caller, view: self, text: text, className: className)
    }

    func captureTouchInfo(gestureRecognizer: UITapGestureRecognizer, type: NIDEventName) {
        let location = gestureRecognizer.location(in: self)
        captureTouchEvent(type: type, view: gestureRecognizer.view, location: location)
    }

    func captureLongTouchInfo(gestureRecognizer: UILongPressGestureRecognizer, type: NIDEventName, beginEndType: String) {
        let location = gestureRecognizer.location(in: self)
        captureTouchEvent(type: type, view: gestureRecognizer.view, location: location, extraAttr: ["type": beginEndType])
    }
}
