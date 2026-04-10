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
                self?.captureEvent(event: NIDEvent(type: .screenCapture))
            }
        )

        // Screen Recording Events for <iOS 17.0
        if #unavailable(iOS 17.0) {
            appEventObservers.append(
                NotificationCenter.default.addObserver(
                    forName: UIScreen.capturedDidChangeNotification,
                    object: UIScreen.main,
                    queue: .main
                ) { [weak self] _ in
                    self?.screenRecording(isCaptured: UIScreen.main.isCaptured)
                }
            )
        }
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

    func screenRecording(isCaptured: Bool) {
        captureEvent(event: NIDEvent(type: isCaptured ? .screenRecordingStarted : .screenRecordingStopped))
    }

    func observeSceneCaptureEvents(inScreen controller: UIViewController?) {
        guard #available(iOS 17.0, *), let scene = controller?.viewIfLoaded?.window?.windowScene else { return }

        let sceneID = scene.session.persistentIdentifier
        if NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID[sceneID] == nil {
            let initialActive = scene.traitCollection.sceneCaptureState == .active
            NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID[sceneID] = initialActive

            let registration = scene.registerForTraitChanges([UITraitSceneCaptureState.self]) {
                [weak self] (windowScene: UIWindowScene, previousTraitCollection: UITraitCollection) in
                self?.captureSceneCaptureStateChange(
                    sceneID: windowScene.session.persistentIdentifier,
                    isActive: windowScene.traitCollection.sceneCaptureState == .active
                )
            }
            NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID[sceneID] = registration as AnyObject

            if initialActive {
                screenRecording(isCaptured: true)
            }
        } else {
            captureSceneCaptureStateChange(
                sceneID: sceneID,
                isActive: scene.traitCollection.sceneCaptureState == .active
            )
        }
    }

    @available(iOS 17.0, *)
    func captureSceneCaptureStateChange(sceneID: String, isActive: Bool) {
        guard NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID[sceneID] != isActive else { return }
        NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID[sceneID] = isActive
        screenRecording(isCaptured: isActive)
    }
}
