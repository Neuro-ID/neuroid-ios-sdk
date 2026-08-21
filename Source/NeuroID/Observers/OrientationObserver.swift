//
//  OrientationObserver.swift
//  NeuroID
//

import UIKit

protocol SessionObserver: Sendable {
    func start() async
    func stop() async
}

final class OrientationObserver: SessionObserver {
    private let eventService: EventStorageServiceProtocol
    private let notificationCenter: NotificationCenter

    private var token: NSObjectProtocol?

    nonisolated init(eventService: EventStorageServiceProtocol, notificationCenter: NotificationCenter = .default) {
        self.eventService = eventService
        self.notificationCenter = notificationCenter
    }

    func start() {
        guard token == nil else { return }
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        token = notificationCenter.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.record(UIDevice.current.orientation)
            }
        }
    }

    func stop() {
        guard let token else { return }
        notificationCenter.removeObserver(token)
        self.token = nil
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    func record(_ orientation: UIDeviceOrientation) async {
        let tg = [
            "orientation": TargetValue.string(orientation.description),
        ]
        
        eventService.saveEventToLocalDataStore(
            NIDEvent(
                type: NIDEventName.windowOrientationChange,
                tg: tg
            )
        )
        eventService.saveEventToLocalDataStore(
            NIDEvent(
                type: NIDEventName.deviceOrientation,
                tg: tg
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
