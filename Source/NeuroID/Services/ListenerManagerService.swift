//
//  ListenerManagerService.swift
//  NeuroID
//

import Foundation
import UIKit

protocol ListenerManagerServiceProtocol {
    func startAppEventListeners()
    func stopAppEventListeners()
}

final class ListenerManagerService: ListenerManagerServiceProtocol {

    let uiRuntime: UIRuntime
    let notificationCenter: NotificationCenter
    private var appEventObservers: [NSObjectProtocol] = []

    init(uiRuntime: UIRuntime, notificationCenter: NotificationCenter) {
        self.uiRuntime = uiRuntime
        self.notificationCenter = notificationCenter
    }

    func startAppEventListeners() {
        guard appEventObservers.isEmpty else { return }

        startScreenshotObserver()
        startScreenRecordingObserver()

        // notification won't fire if recording was already active when the SDK starts
        updateScreenRecordingStateIfChanged(isActive: UIScreen.main.isCaptured)
    }

    func stopAppEventListeners() {
        guard !appEventObservers.isEmpty else { return }

        for observer in appEventObservers {
            notificationCenter.removeObserver(observer)
        }
        appEventObservers.removeAll()

        uiRuntime.resetScreenCaptureTrackingState()
    }
}

// MARK: - Observer Registration
extension ListenerManagerService {
    func startScreenshotObserver() {
        appEventObservers.append(
            notificationCenter.addObserver(
                forName: UIApplication.userDidTakeScreenshotNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.captureEvent(event: NIDEvent(type: .screenCapture))
            }
        )
    }

    func startScreenRecordingObserver() {
        appEventObservers.append(
            notificationCenter.addObserver(
                forName: UIScreen.capturedDidChangeNotification,
                object: UIScreen.main,
                queue: .main
            ) { [weak self] _ in
                self?.updateScreenRecordingStateIfChanged(isActive: UIScreen.main.isCaptured)
            }
        )
    }
}

// MARK: - Screen Recording State
extension ListenerManagerService {
    func updateScreenRecordingStateIfChanged(isActive: Bool) {
        let previousState: Bool? = uiRuntime.screenCaptureLastKnownState
        uiRuntime.screenCaptureLastKnownState = isActive

        guard previousState != isActive else { return }

        // Only emit the initial observation if capture was already active
        guard previousState != nil || isActive else { return }

        captureEvent(
            event: NIDEvent(
                type: .screenRecording,
                attrs: [Attrs(n: "state", v: isActive ? "active" : "inactive")]
            )
        )
    }
}

// MARK: - Event Capture
extension ListenerManagerService {
    fileprivate func captureEvent(event: NIDEvent) {
        var event = event
        event.url = NeuroID.getScreenName()
        NeuroIDCore.shared.saveEventToLocalDataStore(
            event,
            screen: NeuroID.getScreenName() ?? ParamsCreator.generateID()
        )
    }
}
