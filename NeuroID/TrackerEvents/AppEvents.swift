//
//  AppEvents.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

// MARK: - App events

internal extension NeuroIDTracker {
    static func observeAppEvents() {
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(NeuroIDTracker.appMovedToBackground), name: UIScene.willDeactivateNotification, object: nil)

            NotificationCenter.default.addObserver(self, selector: #selector(NeuroIDTracker.appMovedToForeground), name: UIScene.willEnterForegroundNotification, object: nil)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(NeuroIDTracker.appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)

            NotificationCenter.default.addObserver(self, selector: #selector(NeuroIDTracker.appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        }
    }

    @objc static func appMovedToBackground() {
        NeuroIDTracker.captureEvent(event: NIDEvent(type: NIDEventName.windowBlur))
    }

    @objc static func appMovedToForeground() {
        NeuroIDTracker.captureEvent(event: NIDEvent(type: NIDEventName.windowFocus))
    }
}
