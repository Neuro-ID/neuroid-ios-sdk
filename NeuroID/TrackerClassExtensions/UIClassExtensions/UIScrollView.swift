//
//  UIScrollView.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/24/23.
//

import Foundation
import UIKit

private func UIScrollViewSwizzling(element: UIScrollView.Type,
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

internal extension UIScrollView {
    func testMethod() {
        print("test")
    }

//
    static func startSwizzlingUIScroll() {
        let scrollView = UIScrollView.self

        UIScrollViewSwizzling(element: scrollView,
                              originalSelector: #selector(scrollView.setContentOffset(_:animated:)),
                              swizzledSelector: #selector(scrollView.swizzledSetContentOffset))

        UIScrollViewSwizzling(element: scrollView,
                              originalSelector: #selector(scrollView.scrollRectToVisible(_:animated:)),
                              swizzledSelector: #selector(scrollView.swizzledScrollRectToVisible))

        //
        //        textFieldSwizzling(element: textField,
        //                           originalSelector: #selector(textField.copy(_:)),
        //                           swizzledSelector: #selector(textField.neuroIDCopy))
        //
        //        textFieldSwizzling(element: textField,
        //                           originalSelector: #selector(textField.paste(_:)),
        //                           swizzledSelector: #selector(textField.neuroIDPaste))
    }

//
//    // Swizzled implementation of setContentOffset(_:animated:)
//    @objc func swizzledSetContentOffset(_ contentOffset: CGPoint, animated: Bool) {
//        // Your custom logic here, before calling the original method if needed
//        // For example, you can log the content offset, perform additional actions, etc.
//
//        print("\(Constants.debugTest.rawValue) - UIVIEW - x=\(contentOffset.x) y=\(contentOffset.y)")
//
//        // Call the original method
//        swizzledSetContentOffset(contentOffset, animated: animated)
//    }

    @objc private func swizzledSetContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        // Your custom logic here, before calling the original method if needed
        // For example, you can log the content offset, perform additional actions, etc.

//        print("\(Constants.debugTest.rawValue) - content off - x=\(contentOffset.x) y=\(contentOffset.y) ")
        // Call the original method
        swizzledSetContentOffset(contentOffset, animated: animated)
    }

    @objc private func swizzledScrollRectToVisible(_ rect: CGRect, animated: Bool) {
        // Your custom logic here, before calling the original method if needed
        // For example, you can log the scrollRectToVisible parameters, perform additional actions, etc.

//        print("\(Constants.debugTest.rawValue) - rect - x=\(rect.height) y=\(rect.width)")

        // Call the original method
        swizzledScrollRectToVisible(rect, animated: animated)
    }
}
