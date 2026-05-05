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
                self?.handleScreenshotNotification()
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
                self?.handleLegacyScreenCaptureChange(isCaptured: UIScreen.main.isCaptured)
            }
        )
    }
}

// MARK: - Notification Handlers
extension ListenerManagerService {
    func handleScreenshotNotification() {
        captureEvent(event: NIDEvent(type: .screenCapture))
    }

    func handleLegacyScreenCaptureChange(isCaptured: Bool) {
        updateScreenRecordingStateIfChanged(isActive: isCaptured)
    }
}


// MARK: - Screen Recording State
extension ListenerManagerService {
    func updateScreenRecordingStateIfChanged(isActive: Bool) {
        var event = NIDEvent(type: .screenRecording)
        if uiRuntime.screenCaptureLastKnownState == nil {
            // first observation — only emit if already active to avoid a spurious "inactive" on cold start
            uiRuntime.screenCaptureLastKnownState = isActive
            if isActive {
                event.attrs = [Attrs(n: "state", v: "active")]
                captureEvent(event: event)
            }
            return
        }
        // dedupe repeated notifications for unchanged capture state
        guard uiRuntime.screenCaptureLastKnownState != isActive else { return }
        uiRuntime.screenCaptureLastKnownState = isActive
        event.attrs = [Attrs(n: "state", v: isActive ? "active" : "inactive")]
        captureEvent(event: event)
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
