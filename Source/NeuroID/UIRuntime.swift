//
//  UIRuntime.swift
//  NeuroID
//

import UIKit

final class UIRuntime {

    var didSwizzle: Bool = false

    var screenCaptureLastKnownState: Bool?

    init() {
        // init should not be isolated so NeuroIDCore can start it
    }

    func resetScreenCaptureTrackingState() {
        screenCaptureLastKnownState = nil
    }

    func swizzle() {
        guard !didSwizzle else { return }

        UIViewController.startSwizzling()
        UITextField.startSwizzling()
        UITextView.startSwizzling()
        UINavigationController.swizzleNavigation()
        UITableView.tableviewSwizzle()

        didSwizzle = true
    }
}
