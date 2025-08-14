//
//  DeviceEvents.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

// MARK: - Device events

extension NeuroIDTracker {
    func observeRotation() {
        NotificationCenter.default.addObserver(self, selector: #selector(deviceRotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    @objc func deviceRotated(notification: Notification) {
        let orientation: String = ParamsCreator.getOrientation()

        let viewId = TargetValue.string("")
        let tg = [
            "\(Constants.orientationKey.rawValue)": TargetValue.string(orientation),
            "\(Constants.tgsKey.rawValue)": viewId
        ]

        captureEvent(
            event: NIDEvent(
                type: NIDEventName.windowOrientationChange,
                tg: tg,
                tgs: viewId.toString(),
                url: NeuroID.getScreenName() ?? ""
            )
        )
        captureEvent(
            event: NIDEvent(
                type: NIDEventName.deviceOrientation,
                tg: tg,
                tgs: viewId.toString(),
                url: NeuroID.getScreenName() ?? ""
            )
        )
    }
}
