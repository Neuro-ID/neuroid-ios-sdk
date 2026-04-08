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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appMovedToBackground),
            name: UIScene.willDeactivateNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appMovedToForeground),
            name: UIScene.didActivateNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appLowMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // Screenshot Events
        appEventObservers.append(
            NotificationCenter.default.addObserver(
                forName: UIApplication.userDidTakeScreenshotNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.screenCapture()
            }
        )

        // Screen Recording Events
        appEventObservers.append(
            NotificationCenter.default.addObserver(
                forName: UIScreen.capturedDidChangeNotification,
                object: UIScreen.main,
                queue: .main
            ) { [weak self] _ in
                self?.screenRecording()
            }
        )
                
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
        if !NeuroIDCore.shared.lowMemory {
            NeuroIDCore.clearDataStore()

            NeuroIDCore.shared.send(
                forceSend: true,
                eventSubset: [
                    NIDEvent(
                        type: NIDEventName.lowMemory,
                        url: NeuroID.getScreenName() ?? "low_mem_no_screen"
                    )
                ]
            )

            NeuroIDCore.shared.lowMemory = true
        }

        let lowMembackOffTime = NeuroIDCore.shared.configService.configCache.lowMemoryBackOff ?? ConfigService.DEFAULT_LOW_MEMORY_BACK_OFF

        DispatchQueue.main.asyncAfter(deadline: .now() + lowMembackOffTime) {
            NeuroIDCore.shared.lowMemory = false
        }
    }

    func screenCapture() {
        captureEvent(event: NIDEvent(type: .screenCapture))
    }

    func screenRecording() {
        captureEvent(event: NIDEvent(type: .screenRecording))
    }
}
