//
//  AppLifecycleObserverTests.swift
//  NeuroID
//

import Testing
import UIKit

@testable import NeuroID

@Suite
struct AppLifecycleObserverTests {
    let notificationCenter: NotificationCenter
    let dataStore: DataStore
    let eventService: EventStorageService
    let observer: AppLifecycleObserver

    init() {
        notificationCenter = NotificationCenter()
        dataStore = DataStore()
        eventService = EventStorageService()

        NeuroIDCore.shared.datastore = dataStore
        NeuroIDCore.shared._isSDKStarted = true

        observer = AppLifecycleObserver(
            eventService: eventService,
            notificationCenter: notificationCenter
        )
    }

    @Test("Captures a window blur event when the app enters background")
    func recordsEnteringBackground() async {
        await observer.start()
        notificationCenter.post(name: UIScene.willDeactivateNotification, object: nil)

        let events = dataStore.getAndRemoveAllEvents()
        #expect(events.contains { $0.type == NIDEventName.windowBlur.rawValue })

        await observer.stop()
    }

    @Test("Captures a window focus event when the app enters foreground")
    func recordsEnteringForeground() async {
        await observer.start()
        notificationCenter.post(name: UIScene.didActivateNotification, object: nil)

        let events = dataStore.getAndRemoveAllEvents()
        #expect(events.contains { $0.type == NIDEventName.windowFocus.rawValue })

        await observer.stop()
    }

    @Test("Does not capture events after the observer has been stopped")
    func doesNotReactAfterStop() async {
        await observer.start()
        await observer.stop()

        notificationCenter.post(name: UIScene.didActivateNotification, object: nil)
        notificationCenter.post(name: UIScene.willDeactivateNotification, object: nil)

        #expect(await dataStore.getAllEventCount() == 0)
    }
}
