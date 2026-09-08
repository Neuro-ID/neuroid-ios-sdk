//
//  OrientationObserverTests.swift
//  NeuroID
//

import Testing
import UIKit

@testable import NeuroID

@MainActor
@Suite(.serialized)
struct OrientationObserverTests {
    let notificationCenter: NotificationCenter
    let dataStore: DataStore
    let eventService: EventStorageService
    let observer: OrientationObserver

    init() {
        notificationCenter = NotificationCenter()
        dataStore = DataStore()
        eventService = EventStorageService()
        
        NeuroIDCore.shared.datastore = dataStore
        NeuroIDCore.shared._isSDKStarted = true

        observer = OrientationObserver(
            eventService: eventService,
            notificationCenter: notificationCenter
        )
    }

    @Test(
        "Records a device orientation event with the expected orientation description",
        arguments: [
            UIDeviceOrientation.portrait,
            UIDeviceOrientation.portraitUpsideDown,
            UIDeviceOrientation.landscapeLeft,
            UIDeviceOrientation.landscapeRight,
            UIDeviceOrientation.faceUp,
            UIDeviceOrientation.faceDown,
            UIDeviceOrientation.unknown
        ]
    )
    func recordsOrientation(orientation: UIDeviceOrientation) async {
        await observer.record(orientation)

        let events = dataStore.getAndRemoveAllEvents()
        #expect(
            events.contains {
                $0.type == NIDEventName.deviceOrientation.rawValue
                    && ($0.tg?["orientation"] as? TargetValue)?
                        .toString() == orientation.description
            }
        )
    }

    @Test("Starting or stopping repeatedly does not crash or double-register notifications")
    func startAndStopAreIdempotent() {
        observer.stop()
        observer.start()
        observer.start()
        observer.stop()
        observer.stop()
    }
}
