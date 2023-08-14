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
    static func startSwizzlingUIScroll() {
        let scrollView = UIScrollView.self

        UIScrollViewSwizzling(element: scrollView,
                              originalSelector: #selector(scrollView.setContentOffset(_:animated:)),
                              swizzledSelector: #selector(scrollView.swizzledSetContentOffset))

        UIScrollViewSwizzling(element: scrollView,
                              originalSelector: #selector(scrollView.scrollRectToVisible(_:animated:)),
                              swizzledSelector: #selector(scrollView.swizzledScrollRectToVisible))
    }

    @objc private func swizzledSetContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        swizzledSetContentOffset(contentOffset, animated: animated)
    }

    @objc private func swizzledScrollRectToVisible(_ rect: CGRect, animated: Bool) {
        swizzledScrollRectToVisible(rect, animated: animated)
    }
}
