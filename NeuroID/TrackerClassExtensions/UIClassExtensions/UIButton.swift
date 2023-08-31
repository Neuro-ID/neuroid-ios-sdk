//
//  UIButton.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

// TO-DO - Decide if necessary to capture more than touches already captured

// private func uiButtonSwizzling(element: UIButton.Type,
//                               originalSelector: Selector,
//                               swizzledSelector: Selector)
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

// private extension UIButton {
//    @objc static func startSwizzling() {
//        let uiButton = UIButton.self
//
//        uiButtonSwizzling(element: uiButton,
//                          originalSelector: #selector(uiButton.touchesBegan(_:with:)),
//                  swizzledSelector: #selector(uiButton.nidButtonPress))
//    }
//
//    @objc func nidButtonPress(_ touches: Set<UITouch>, with event: UIEvent?) {
//
//
//        self.nidButtonPress(touches, with: event)
////        if (self.responds(to: #selector(touchesBegan))) {
////            self.nidButtonPress(touches, with: event)
////        }
////
//        if (NeuroID.isStopped()){
//            return
//        }
//        if (self.responds(to: #selector(getter: titleLabel))) {
//            let lengthValue = "\(Constants.eventValuePrefix.rawValue)\(self.titleLabel?.text?.count ?? 0)"
//            let clickTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.click, view: self, type: NIDEventName.click.rawValue, attrParams: ["v": lengthValue, "\(Constants.hashKey.rawValue)": self.titleLabel?.text])
//            var clickEvent = NIDEvent(type: NIDEventName.click, tg: clickTG)
//
//            let screenName = self.className ?? ParamsCreator.genId()
//            var newEvent = clickEvent
//            // Make sure we have a valid url set
//            newEvent.url = screenName
//            DataStore.insertEvent(screen: screenName, event: newEvent)
//            NeuroID.logDebug(category: "saveEvent", content: "save event finish")
//        }
////        super.touchesBegan(touches, with: event)
//    }
// }
