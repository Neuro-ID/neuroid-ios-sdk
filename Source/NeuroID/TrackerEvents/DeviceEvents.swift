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
    func observeRotation() {
        NotificationCenter.default.addObserver(self, selector: #selector(deviceRotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    @objc func deviceRotated(notification: Notification) {
        let orientation: String = ParamsCreator.getOrientation()

        captureEvent(
            event: NIDEvent(
                type: NIDEventName.windowOrientationChange,
                tg: ["\(Constants.orientationKey.rawValue)": TargetValue.string(orientation)],
                view: nil
            )
        )
        captureEvent(
            event: NIDEvent(
                type: NIDEventName.deviceOrientation,
                tg: ["\(Constants.orientationKey.rawValue)": TargetValue.string(orientation)],
                view: nil
            )
        )
    }
}
