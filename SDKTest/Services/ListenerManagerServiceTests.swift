//
//  ListenerManagerServiceTests.swift
//  NeuroID
//

import Testing
import UIKit

@testable import NeuroID

@Suite(.serialized)
struct ListenerManagerServiceTests {

    var uiRuntime: UIRuntime
    var notificationCenter: NotificationCenter
    var listenerManagerService: ListenerManagerService
    var dataStore: DataStore

    init() {
        self.uiRuntime = UIRuntime()
        self.notificationCenter = NotificationCenter()
        self.listenerManagerService = ListenerManagerService(
            uiRuntime: uiRuntime,
            notificationCenter: notificationCenter
        )
        self.dataStore = DataStore()
        NeuroIDCore.shared._isSDKStarted = true
        NeuroIDCore.shared.datastore = dataStore
        uiRuntime.resetScreenCaptureTrackingState()
    }

    func screenRecordingEvents() -> [NIDEvent] {
        dataStore.getAllEvents().filter { $0.type == NIDEventName.screenRecording.rawValue }
    }

    @Test
    func startAppEventListeners_screenshotObserverRegisteredOnce() {
        listenerManagerService.startAppEventListeners()
        listenerManagerService.startAppEventListeners()
        listenerManagerService.startAppEventListeners()
        notificationCenter.post(name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        let screenshotEvents = dataStore.getAllEvents().filter {
            $0.type == NIDEventName.screenCapture.rawValue
        }
        #expect(screenshotEvents.count == 1)
    }

    @Test
    func stopAppEventListeners_removesObservers() {
        listenerManagerService.startAppEventListeners()
        listenerManagerService.stopAppEventListeners()
        notificationCenter.post(name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        let screenshotEvents = dataStore.getAllEvents().filter {
            $0.type == NIDEventName.screenCapture.rawValue
        }
        #expect(screenshotEvents.isEmpty)
    }

    @Test
    func stopAppEventListeners_clearsScreenCaptureTrackingState() {
        listenerManagerService.startAppEventListeners()
        uiRuntime.screenCaptureLastKnownState = true
        listenerManagerService.stopAppEventListeners()
        #expect(uiRuntime.screenCaptureLastKnownState == nil)
    }

    @Test
    func startAppEventListeners_setsInitialRecordingState() {
        listenerManagerService.startAppEventListeners()
        #expect(uiRuntime.screenCaptureLastKnownState == UIScreen.main.isCaptured)
    }

    @Test
    func updateScreenRecordingStateIfChanged_emitsActiveAndInactiveOnTransitions() {
        listenerManagerService.updateScreenRecordingStateIfChanged(isActive: true)
        listenerManagerService.updateScreenRecordingStateIfChanged(isActive: true)
        listenerManagerService.updateScreenRecordingStateIfChanged(isActive: false)
        let events = screenRecordingEvents()
        #expect(events.count == 2)
        #expect(events[0].attrs == [Attrs(n: "state", v: "active")])
        #expect(events[1].attrs == [Attrs(n: "state", v: "inactive")])
        #expect(uiRuntime.screenCaptureLastKnownState == false)
    }

    @Test
    func handleLegacyScreenCaptureChange_updatesRecordingState() {
        listenerManagerService.updateScreenRecordingStateIfChanged(isActive: false)
        listenerManagerService.updateScreenRecordingStateIfChanged(isActive: true)
        listenerManagerService.updateScreenRecordingStateIfChanged(isActive: false)
        let events = screenRecordingEvents()
        #expect(events.count == 2)
        #expect(events[0].attrs == [Attrs(n: "state", v: "active")])
        #expect(events[1].attrs == [Attrs(n: "state", v: "inactive")])
        #expect(uiRuntime.screenCaptureLastKnownState == false)
    }

    @Test
    func startLegacyScreenRecordingObserver_observesCapturedDidChange() {
        listenerManagerService.startAppEventListeners()
        notificationCenter.post(name: UIScreen.capturedDidChangeNotification, object: UIScreen.main)
        #expect(uiRuntime.screenCaptureLastKnownState == UIScreen.main.isCaptured)
    }
}
