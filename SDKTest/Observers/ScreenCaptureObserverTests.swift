//
//  ScreenCaptureObserverTests.swift
//  NeuroID
//

import Testing
import UIKit

@testable import NeuroID

@MainActor
@Suite(.serialized)
struct ScreenCaptureObserverTests {
    let notificationCenter: NotificationCenter
    let dataStore: DataStore
    let eventService: EventStorageService
    let observer: ScreenCaptureObserver

    init() {
        notificationCenter = NotificationCenter()
        dataStore = DataStore()
        eventService = EventStorageService()
        
        NeuroIDCore.shared._isSDKStarted = true
        NeuroIDCore.shared.datastore = dataStore

        observer = ScreenCaptureObserver(
            eventService: eventService,
            notificationCenter: notificationCenter
        )
    }

    @Test("Captures a screen capture event when a screenshot is taken")
    func recordsScreenshot() async {
        observer.start()

        notificationCenter.post(name: UIApplication.userDidTakeScreenshotNotification, object: nil)

        let events = dataStore.getAndRemoveAllEvents()
        #expect(events.contains { $0.type == NIDEventName.screenCapture.rawValue })
        #expect(events.count == 1)

        observer.stop()
    }

    @Test("Does not capture events after the observer has been stopped")
    func doesNotReactAfterStop() async {
        observer.start()
        observer.stop()

        notificationCenter.post(name: UIApplication.userDidTakeScreenshotNotification, object: nil)

        #expect(dataStore.getAllEventCount() == 0)
    }

    @Test("Stopping the observer clears the last known screen capture tracking state")
    func stopClearsScreenCaptureTrackingState() {
        observer.start()
        observer.screenCaptureLastKnownState = true
        observer.stop()
        #expect(observer.screenCaptureLastKnownState == nil)
    }

    @Test("Starting the observer sets the initial screen recording state")
    func startSetsInitialRecordingState() {
        observer.start()
        #expect(observer.screenCaptureLastKnownState == UIScreen.main.isCaptured)
    }

    @Test("Emits active and inactive screen recording events on state transitions")
    func emitsActiveAndInactiveOnStateTransitions() async {
        observer.updateScreenRecordingStateIfChanged(isActive: true)
        observer.updateScreenRecordingStateIfChanged(isActive: true)
        observer.updateScreenRecordingStateIfChanged(isActive: false)

        let events = dataStore.getAndRemoveAllEvents()
        #expect(events.count == 2)

        #expect(events[0].attrs == [Attrs(n: "state", v: "active")])
        #expect(events[1].attrs == [Attrs(n: "state", v: "inactive")])
        #expect(observer.screenCaptureLastKnownState == false)
    }

    @Test("Does not emit for an initial inactive state, but emits on subsequent transitions")
    func emitsEventsAfterInitialInactiveState() async {
        observer.updateScreenRecordingStateIfChanged(isActive: false)
        observer.updateScreenRecordingStateIfChanged(isActive: true)
        observer.updateScreenRecordingStateIfChanged(isActive: false)

        let events = dataStore.getAndRemoveAllEvents()
        #expect(events.count == 2)
        #expect(events[0].attrs == [Attrs(n: "state", v: "active")])
        #expect(events[1].attrs == [Attrs(n: "state", v: "inactive")])
        #expect(observer.screenCaptureLastKnownState == false)
    }

    @Test("Starting the observer updates state in response to the captured-did-change notification")
    func startObservesCapturedDidChangeNotification() {
        observer.start()
        notificationCenter.post(name: UIScreen.capturedDidChangeNotification, object: UIScreen.main)
        #expect(observer.screenCaptureLastKnownState == UIScreen.main.isCaptured)
    }

}
