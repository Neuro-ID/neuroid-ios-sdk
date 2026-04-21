//
//  ListenerManagerServiceTests.swift
//  NeuroID
//

import Testing
import UIKit

@testable import NeuroID

@Suite
@MainActor
struct ListenerManagerServiceTests {

    var notificationCenter: NotificationCenter
    var listenerManagerService: ListenerManagerService
    var dataStore: DataStore

    init() {
        self.notificationCenter = NotificationCenter()
        self.listenerManagerService = ListenerManagerService(notificationCenter: notificationCenter)
        self.dataStore = DataStore()
        NeuroIDCore.shared._isSDKStarted = true
        NeuroIDCore.shared.datastore = dataStore
        NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID.removeAll()
        NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID.removeAll()
        NeuroIDCore.shared.screenCaptureLastKnownState = nil
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
        NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID["scene"] = NSObject()
        NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID["scene"] = true
        NeuroIDCore.shared.screenCaptureLastKnownState = true
        listenerManagerService.stopAppEventListeners()
        #expect(NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID.isEmpty)
        #expect(NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID.isEmpty)
        #expect(NeuroIDCore.shared.screenCaptureLastKnownState == nil)
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
        #expect(NeuroIDCore.shared.screenCaptureLastKnownState == false)
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
        #expect(NeuroIDCore.shared.screenCaptureLastKnownState == false)
    }

    @Test
    func startLegacyScreenRecordingObserver_observesCapturedDidChange() async {
        listenerManagerService.startLegacyScreenRecordingObserver()
        notificationCenter.post(name: UIScreen.capturedDidChangeNotification, object: UIScreen.main)
        await Task.yield()
        #expect(NeuroIDCore.shared.screenCaptureLastKnownState == UIScreen.main.isCaptured)
    }

    @available(iOS 17.0, *)
    @Test
    func registerSceneIfNeeded_registersConnectedSceneState() {
        let scenes = connectedWindowScenes()
        guard let scene = scenes.first else { return }
        NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID.removeAll()
        NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID.removeAll()
        listenerManagerService.registerSceneIfNeeded(scene)
        let sceneID = scene.session.persistentIdentifier
        #expect(NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID[sceneID] != nil)
        #expect(
            NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID[sceneID]
                == (scene.traitCollection.sceneCaptureState == .active)
        )
    }

    @available(iOS 17.0, *)
    @Test
    func registerExistingScenes_registersEachConnectedScene() {
        let scenes = connectedWindowScenes()
        guard !scenes.isEmpty else { return }
        NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID.removeAll()
        NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID.removeAll()
        listenerManagerService.registerExistingScenes()
        for scene in scenes {
            let sceneID = scene.session.persistentIdentifier
            #expect(NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID[sceneID] != nil)
            #expect(
                NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID[sceneID]
                    == (scene.traitCollection.sceneCaptureState == .active)
            )
        }
    }

    @available(iOS 17.0, *)
    @Test
    func handleSceneDidActivate_registersSceneIfNeeded() {
        let scenes = connectedWindowScenes()
        guard let scene = scenes.first else { return }
        NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID.removeAll()
        NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID.removeAll()
        listenerManagerService.handleSceneDidActivate(scene)
        let sceneID = scene.session.persistentIdentifier
        #expect(NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID[sceneID] != nil)
        #expect(
            NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID[sceneID]
                == (scene.traitCollection.sceneCaptureState == .active)
        )
    }

    @available(iOS 17.0, *)
    @Test
    func handleSceneCaptureTraitChange_updatesAggregateAndEmitsInactive() {
        NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID["sceneA"] = true
        NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID["sceneB"] = false
        NeuroIDCore.shared.screenCaptureLastKnownState = true
        listenerManagerService.handleSceneCaptureTraitChange(sceneID: "sceneA", isActive: false)
        #expect(NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID["sceneA"] == false)
        #expect(NeuroIDCore.shared.screenCaptureLastKnownState == false)
        #expect(screenRecordingEvents().last?.attrs == [Attrs(n: "state", v: "inactive")])
    }

    @available(iOS 17.0, *)
    @Test
    func sceneDidDisconnect_removesSceneAndRefreshesAggregate() {
        NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID["sceneA"] = NSObject()
        NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID["sceneA"] = true
        NeuroIDCore.shared.screenCaptureLastKnownState = true
        listenerManagerService.sceneDidDisconnect(sceneID: "sceneA")
        #expect(NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID["sceneA"] == nil)
        #expect(NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID["sceneA"] == nil)
        #expect(NeuroIDCore.shared.screenCaptureLastKnownState == false)
        #expect(screenRecordingEvents().last?.attrs == [Attrs(n: "state", v: "inactive")])
    }

    @available(iOS 17.0, *)
    @Test
    func handleSceneDidDisconnect_routesToSceneDisconnectFlow() {
        NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID["sceneB"] = NSObject()
        NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID["sceneB"] = true
        NeuroIDCore.shared.screenCaptureLastKnownState = true
        listenerManagerService.handleSceneDidDisconnect(sceneID: "sceneB")
        #expect(NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID["sceneB"] == nil)
        #expect(NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID["sceneB"] == nil)
        #expect(NeuroIDCore.shared.screenCaptureLastKnownState == false)
    }
}
