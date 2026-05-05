//
//  UIRuntime.swift
//  NeuroID
//

import UIKit

//@MainActor
final class UIRuntime {

    var didSwizzle: Bool = false

    var sceneCaptureRegistrationsBySceneID: [String: AnyObject] = [:]
    var sceneCaptureLastKnownStateBySceneID: [String: Bool] = [:]
    var screenCaptureLastKnownState: Bool?

    nonisolated init() {
        // init should not be isolated so NeuroIDCore can start it
    }

    func resetScreenCaptureTrackingState() {
        sceneCaptureRegistrationsBySceneID.removeAll()
        sceneCaptureLastKnownStateBySceneID.removeAll()
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
