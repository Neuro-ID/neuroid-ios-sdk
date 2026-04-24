//
//  UIRuntime.swift
//  NeuroID
//

import Foundation

@MainActor final class UIRuntime {

    var sceneCaptureRegistrationsBySceneID: [String: AnyObject] = [:]
    var sceneCaptureLastKnownStateBySceneID: [String: Bool] = [:]
    var screenCaptureLastKnownState: Bool?

    nonisolated init() {}

    func resetScreenCaptureTrackingState() {
        sceneCaptureRegistrationsBySceneID.removeAll()
        sceneCaptureLastKnownStateBySceneID.removeAll()
        screenCaptureLastKnownState = nil
    }
}
