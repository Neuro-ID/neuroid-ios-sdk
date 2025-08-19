//
//  AppEvents.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

// MARK: - App events

extension NeuroIDTracker {
    func observeAppEvents() {
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIScene.willDeactivateNotification, object: nil)

            NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIScene.didActivateNotification, object: nil)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)

            NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(appLowMemoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }

    @objc func appMovedToBackground() {
        captureEvent(event: NIDEvent(type: NIDEventName.windowBlur))
    }

    @objc func appMovedToForeground() {
        captureEvent(event: NIDEvent(type: NIDEventName.windowFocus))
    }

    @objc func appLowMemoryWarning() {
        // Reduce memory footprint
        // Only clear this event queue the first time as it might be triggered a few times in a row (dropping our low mem event)
        if !NeuroID.shared.lowMemory {
            NeuroID.clearDataStore()

            NeuroID.shared.send(
                forceSend: true,
                eventSubset: [
                    NIDEvent(
                        type: NIDEventName.lowMemory,
                        url: NeuroID.getScreenName() ?? "low_mem_no_screen"
                    )
                ]
            )

            NeuroID.shared.lowMemory = true
        }

        let lowMembackOffTime = NeuroID.shared.configService.configCache.lowMemoryBackOff ?? NIDConfigService.DEFAULT_LOW_MEMORY_BACK_OFF

        DispatchQueue.main.asyncAfter(deadline: .now() + lowMembackOffTime) {
            NeuroID.shared.lowMemory = false
        }
    }
}
