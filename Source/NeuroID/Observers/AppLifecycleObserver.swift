//
//  AppLifecycleObserver.swift
//  NeuroID
//

import UIKit

final class AppLifecycleObserver: SessionObserver {
    private let eventService: EventStorageServiceProtocol
    private let notificationCenter: NotificationCenter

    private var tokens: [NSObjectProtocol] = []

    init(eventService: EventStorageServiceProtocol, notificationCenter: NotificationCenter = .default) {
        self.eventService = eventService
        self.notificationCenter = notificationCenter
    }

    func start() {
        guard tokens.isEmpty else { return }

        tokens.append(
            notificationCenter.addObserver(
                forName: UIScene.didActivateNotification,
                object: nil,
                queue: nil
            ) { [eventService] _ in
                eventService.saveEventToDataStore(NIDEvent(type: .windowFocus))
            }
        )

        tokens.append(
            notificationCenter.addObserver(
                forName: UIScene.willDeactivateNotification,
                object: nil,
                queue: nil
            ) { [eventService] _ in
                eventService.saveEventToDataStore(NIDEvent(type: .windowBlur))
            }
        )
    }

    func stop() {
        for token in tokens {
            notificationCenter.removeObserver(token)
        }
        tokens.removeAll()
    }
}
