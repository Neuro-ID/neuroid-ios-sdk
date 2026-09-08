//
//  ScreenCaptureObserver.swift
//  NeuroID
//

import UIKit

final class ScreenCaptureObserver: SessionObserver {
    private let eventService: EventStorageServiceProtocol
    private let notificationCenter: NotificationCenter

    private var tokens: [NSObjectProtocol] = []

    var screenCaptureLastKnownState: Bool?

    nonisolated init(eventService: EventStorageServiceProtocol, notificationCenter: NotificationCenter = .default) {
        self.eventService = eventService
        self.notificationCenter = notificationCenter
    }

    func start() {
        guard tokens.isEmpty else { return }

        tokens.append(
            notificationCenter.addObserver(
                forName: UIApplication.userDidTakeScreenshotNotification,
                object: nil,
                queue: .main
            ) { [eventService] _ in
                eventService.saveEventToDataStore(
                    NIDEvent(type: .screenCapture)
                )
            }
        )

        tokens.append(
            notificationCenter.addObserver(
                forName: UIScreen.capturedDidChangeNotification,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.updateScreenRecordingStateIfChanged(isActive: UIScreen.main.isCaptured)
                }
            }
        )

        updateScreenRecordingStateIfChanged(isActive: UIScreen.main.isCaptured)
    }

    func stop() {
        for token in tokens {
            notificationCenter.removeObserver(token)
        }
        tokens.removeAll()
        screenCaptureLastKnownState = nil
    }

    func updateScreenRecordingStateIfChanged(isActive: Bool) {
        let previousState: Bool? = screenCaptureLastKnownState
        screenCaptureLastKnownState = isActive

        guard previousState != isActive else { return }

        // Only emit the initial observation if capture was already active
        guard previousState != nil || isActive else { return }

        eventService.saveEventToDataStore(
            NIDEvent(
                type: .screenRecording,
                attrs: [Attrs(n: "state", v: isActive ? "active" : "inactive")]
            )
        )
    }
}
