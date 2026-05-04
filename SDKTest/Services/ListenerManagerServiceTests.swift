//
//  ListenerManagerServiceTests.swift
//  NeuroID
//

import Testing
import UIKit

@testable import NeuroID

@Suite(.serialized)
@MainActor
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

    @available(iOS 17.0, *)
    func connectedWindowScenes() -> [UIWindowScene] {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    }

    @Test
    func startAppEventListeners_screenshotObserverRegisteredOnce() async {
        listenerManagerService.startAppEventListeners()
        listenerManagerService.startAppEventListeners()
        listenerManagerService.startAppEventListeners()
        notificationCenter.post(name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        await Task.yield()
        let screenshotEvents = dataStore.getAllEvents().filter {
            $0.type == NIDEventName.screenCapture.rawValue
        }
        #expect(screenshotEvents.count == 1)
    }

    @Test
    func stopAppEventListeners_removesObservers() async {
        listenerManagerService.startAppEventListeners()
        listenerManagerService.stopAppEventListeners()
        notificationCenter.post(name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        await Task.yield()
        let screenshotEvents = dataStore.getAllEvents().filter {
            $0.type == NIDEventName.screenCapture.rawValue
        }
        #expect(screenshotEvents.isEmpty)
    }

    @Test
    func stopAppEventListeners_clearsScreenCaptureTrackingState() {
        listenerManagerService.startAppEventListeners()
        uiRuntime.sceneCaptureRegistrationsBySceneID["scene"] = NSObject()
        uiRuntime.sceneCaptureLastKnownStateBySceneID["scene"] = true
        uiRuntime.screenCaptureLastKnownState = true
        listenerManagerService.stopAppEventListeners()
        #expect(uiRuntime.sceneCaptureRegistrationsBySceneID.isEmpty)
        #expect(uiRuntime.sceneCaptureLastKnownStateBySceneID.isEmpty)
        #expect(uiRuntime.screenCaptureLastKnownState == nil)
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
        listenerManagerService.handleLegacyScreenCaptureChange(isCaptured: false)
        listenerManagerService.handleLegacyScreenCaptureChange(isCaptured: true)
        listenerManagerService.handleLegacyScreenCaptureChange(isCaptured: false)
        let events = screenRecordingEvents()
        #expect(events.count == 2)
        #expect(events[0].attrs == [Attrs(n: "state", v: "active")])
        #expect(events[1].attrs == [Attrs(n: "state", v: "inactive")])
        #expect(uiRuntime.screenCaptureLastKnownState == false)
    }

    @Test
    func startLegacyScreenRecordingObserver_observesCapturedDidChange() async {
        listenerManagerService.startLegacyScreenRecordingObserver()
        notificationCenter.post(name: UIScreen.capturedDidChangeNotification, object: UIScreen.main)
        await Task.yield()
        #expect(uiRuntime.screenCaptureLastKnownState == UIScreen.main.isCaptured)
    }

    @available(iOS 17.0, *)
    @Test
    func registerSceneIfNeeded_registersConnectedSceneState() {
        let scenes = connectedWindowScenes()
        guard let scene = scenes.first else { return }
        uiRuntime.sceneCaptureRegistrationsBySceneID.removeAll()
        uiRuntime.sceneCaptureLastKnownStateBySceneID.removeAll()
        listenerManagerService.registerSceneIfNeeded(scene)
        let sceneID = scene.session.persistentIdentifier
        #expect(uiRuntime.sceneCaptureRegistrationsBySceneID[sceneID] != nil)
        #expect(
            uiRuntime.sceneCaptureLastKnownStateBySceneID[sceneID]
                == (scene.traitCollection.sceneCaptureState == .active)
        )
    }

    @available(iOS 17.0, *)
    @Test
    func registerExistingScenes_registersEachConnectedScene() {
        let scenes = connectedWindowScenes()
        guard !scenes.isEmpty else { return }
        uiRuntime.sceneCaptureRegistrationsBySceneID.removeAll()
        uiRuntime.sceneCaptureLastKnownStateBySceneID.removeAll()
        listenerManagerService.registerExistingScenes()
        for scene in scenes {
            let sceneID = scene.session.persistentIdentifier
            #expect(uiRuntime.sceneCaptureRegistrationsBySceneID[sceneID] != nil)
            #expect(
                uiRuntime.sceneCaptureLastKnownStateBySceneID[sceneID]
                    == (scene.traitCollection.sceneCaptureState == .active)
            )
        }
    }

    @available(iOS 17.0, *)
    @Test
    func handleSceneDidActivate_registersSceneIfNeeded() {
        let scenes = connectedWindowScenes()
        guard let scene = scenes.first else { return }
        uiRuntime.sceneCaptureRegistrationsBySceneID.removeAll()
        uiRuntime.sceneCaptureLastKnownStateBySceneID.removeAll()
        listenerManagerService.handleSceneDidActivate(scene)
        let sceneID = scene.session.persistentIdentifier
        #expect(uiRuntime.sceneCaptureRegistrationsBySceneID[sceneID] != nil)
        #expect(
            uiRuntime.sceneCaptureLastKnownStateBySceneID[sceneID]
                == (scene.traitCollection.sceneCaptureState == .active)
        )
    }

    @available(iOS 17.0, *)
    @Test
    func handleSceneCaptureTraitChange_updatesAggregateAndEmitsInactive() {
        uiRuntime.sceneCaptureLastKnownStateBySceneID["sceneA"] = true
        uiRuntime.sceneCaptureLastKnownStateBySceneID["sceneB"] = false
        uiRuntime.screenCaptureLastKnownState = true
        listenerManagerService.handleSceneCaptureTraitChange(sceneID: "sceneA", isActive: false)
        #expect(uiRuntime.sceneCaptureLastKnownStateBySceneID["sceneA"] == false)
        #expect(uiRuntime.screenCaptureLastKnownState == false)
        #expect(screenRecordingEvents().last?.attrs == [Attrs(n: "state", v: "inactive")])
    }

    @available(iOS 17.0, *)
    @Test
    func sceneDidDisconnect_removesSceneAndRefreshesAggregate() {
        uiRuntime.sceneCaptureRegistrationsBySceneID["sceneA"] = NSObject()
        uiRuntime.sceneCaptureLastKnownStateBySceneID["sceneA"] = true
        uiRuntime.screenCaptureLastKnownState = true
        listenerManagerService.sceneDidDisconnect(sceneID: "sceneA")
        #expect(uiRuntime.sceneCaptureRegistrationsBySceneID["sceneA"] == nil)
        #expect(uiRuntime.sceneCaptureLastKnownStateBySceneID["sceneA"] == nil)
        #expect(uiRuntime.screenCaptureLastKnownState == false)
        #expect(screenRecordingEvents().last?.attrs == [Attrs(n: "state", v: "inactive")])
    }

    @available(iOS 17.0, *)
    @Test
    func handleSceneDidDisconnect_routesToSceneDisconnectFlow() {
        uiRuntime.sceneCaptureRegistrationsBySceneID["sceneB"] = NSObject()
        uiRuntime.sceneCaptureLastKnownStateBySceneID["sceneB"] = true
        uiRuntime.screenCaptureLastKnownState = true
        listenerManagerService.handleSceneDidDisconnect(sceneID: "sceneB")
        #expect(uiRuntime.sceneCaptureRegistrationsBySceneID["sceneB"] == nil)
        #expect(uiRuntime.sceneCaptureLastKnownStateBySceneID["sceneB"] == nil)
        #expect(uiRuntime.screenCaptureLastKnownState == false)
    }
}
