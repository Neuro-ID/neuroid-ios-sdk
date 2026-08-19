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
        let orientation: String = UIDevice.current.orientation.description

        let viewId = TargetValue.string("")
        let tg = [
            "orientation": TargetValue.string(orientation),
            "\(Constants.tgsKey.rawValue)": viewId
        ]

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

extension UIDeviceOrientation {
    var description: String {
        switch self {
        case .landscapeLeft, .landscapeRight:
            return "Landscape"
        case .portrait, .portraitUpsideDown:
            return "Portrait"
        case .faceUp, .faceDown:
            return "Flat"
        case .unknown:
            return "Unknown"
        @unknown default:
            return "Unknown"
        }
    }
}
