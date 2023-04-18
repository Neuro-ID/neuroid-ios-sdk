//
//  DeviceEvents.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

// MARK: - Device events

internal extension NeuroIDTracker {
    static func observeRotation() {
        NotificationCenter.default.addObserver(self, selector: #selector(NeuroIDTracker.deviceRotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    @objc static func deviceRotated(notification: Notification) {
        let orientation: String
        if UIDevice.current.orientation.isLandscape {
            orientation = "Landscape"
        } else {
            orientation = "Portrait"
        }

//        captureEvent(event: NIDEvent(type: NIDEventName.windowOrientationChange, tg: ["orientation": TargetValue.string(orientation)], view: nil))
//        captureEvent(event: NIDEvent(type: NIDEventName.deviceOrientation, tg: ["orientation": TargetValue.string(orientation)], view: nil))
    }
}
