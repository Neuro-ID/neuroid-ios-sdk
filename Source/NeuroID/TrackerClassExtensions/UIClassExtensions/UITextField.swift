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

extension UITextField {
    func addTapGesture() {
        // Add a single-tap gesture recognizer
        let singleTapGesture = CustomTapGestureRecognizer(target: self, action: #selector(self.handleSingleTap))
        singleTapGesture.accessibilityLabel = self.id
        if !containsGestureRecognizer(recognizers: self.gestureRecognizers, find: singleTapGesture) {
            self.addGestureRecognizer(singleTapGesture)
        }

        // Add a double-tap gesture recognizer
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.accessibilityLabel = self.id
        if !containsGestureRecognizer(recognizers: self.gestureRecognizers, find: doubleTapGesture) {
            self.addGestureRecognizer(doubleTapGesture)
        }

        // Add a long-press gesture recognizer
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        longPressGesture.accessibilityLabel = self.id

        if !containsGestureRecognizer(recognizers: self.gestureRecognizers, find: longPressGesture) {
            self.addGestureRecognizer(longPressGesture)
        }

        // Ensure that single-tap gesture is recognized before double-tap gesture
        singleTapGesture.require(toFail: doubleTapGesture)

        // Ensure that the single-tap gesture is recognized before the long-press gesture
        singleTapGesture.require(toFail: longPressGesture)
    }

    @objc func handleSingleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        captureTouchEvent(
            type: NIDEventName.customTap,
            gestureRecognizer: gestureRecognizer)
        self.becomeFirstResponder()
    }

    @objc func handleDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        captureTouchEvent(
            type: NIDEventName.customDoubleTap,
            gestureRecognizer: gestureRecognizer)
        self.becomeFirstResponder()
    }

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            captureTouchEvent(
                type: NIDEventName.customLongPress,
                gestureRecognizer: gestureRecognizer,
                extraAttr: ["type": "start"])

        } else if gestureRecognizer.state == .ended {
            captureTouchEvent(
                type: NIDEventName.customLongPress,
                gestureRecognizer: gestureRecognizer,
                extraAttr: ["type": "end"])
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

//        textFieldSwizzling(element: textField,
//                           originalSelector: #selector(textField.touchesBegan(_:with:)),
//                           swizzledSelector: #selector(textField.neuroIDTouchStart))
//
//        textFieldSwizzling(element: textField,
//                           originalSelector: #selector(textField.touchesEnded(_:with:)),
//                           swizzledSelector: #selector(textField.neuroIDTouchEnd))
//
//        textFieldSwizzling(element: textField,
//                           originalSelector: #selector(textField.touchesMoved(_:with:)),
//                           swizzledSelector: #selector(textField.neuroIDTouchMoved))
    }

    @objc func neuroIDCut(caller: UIResponder) {
        self.neuroIDCut(caller: caller)
        UtilFunctions.captureContextMenuAction(type: NIDEventName.cut, view: self, text: text, className: nidClassName)
    }

    @objc func neuroIDCopy(caller: UIResponder) {
        self.neuroIDCopy(caller: caller)
        UtilFunctions.captureContextMenuAction(type: NIDEventName.copy, view: self, text: text, className: nidClassName)
    }

    @objc func neuroIDPaste(caller: UIResponder) {
        self.neuroIDPaste(caller: caller)
        UtilFunctions.captureContextMenuAction(type: NIDEventName.paste, view: self, text: text, className: nidClassName)
    }

    @objc func neuroIDTouchStart(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.neuroIDTouchStart(touches, with: event)
        self.touchEvent(sender: self, eventName: .touchStart, touches: touches)
    }

    @objc func neuroIDTouchEnd(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.neuroIDTouchEnd(touches, with: event)
        self.touchEvent(sender: self, eventName: .touchEnd, touches: touches)
    }

    @objc func neuroIDTouchMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.neuroIDTouchMoved(touches, with: event)
        self.touchEvent(sender: self, eventName: .touchMove, touches: touches)
    }

    func touchEvent(sender: UIView, eventName: NIDEventName, touches: Set<UITouch>) {
        let touchArray = UtilFunctions.extractTouchInfoFromTouchArray(touches)
        let tg = ParamsCreator.getTgParams(
            view: sender,
            extraParams: [
                "sender": TargetValue.string(sender.nidClassName),
                "location": TargetValue.string("UITextFieldSwizzle"),
            ])

        NeuroID.saveEventToDataStore(
            UtilFunctions.createTouchEvent(
                sender: sender,
                eventName: eventName,
                location: "UITextFieldSwizzle",
                touches: touchArray)
        )
    }
}

func containsGestureRecognizer(recognizers: [UIGestureRecognizer]?, find: UIGestureRecognizer) -> Bool {
    if let recognizers = recognizers {
        for gr in recognizers {
            if gr.accessibilityLabel == find.accessibilityLabel {
                return true
            }
        }
    }
    return false
}
