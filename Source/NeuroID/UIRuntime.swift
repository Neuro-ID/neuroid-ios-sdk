//
//  UIRuntime.swift
//  NeuroID
//

import Foundation

@MainActor
final class UIRuntime {

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
}
