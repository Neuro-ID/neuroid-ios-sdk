//
//  ListenerManagerServiceTests.swift
//  NeuroID
//

import UIKit
import Testing

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
        NeuroIDCore.shared._isSDKStarted = true
        
        self.dataStore = DataStore()
        NeuroIDCore.shared.datastore = dataStore
    }
    
    @Test
    @MainActor
    func updateScreenRecordingStateIfChanged() {
        listenerManagerService.updateScreenRecordingStateIfChanged(isActive: true)
        listenerManagerService.updateScreenRecordingStateIfChanged(isActive: true)
        listenerManagerService.updateScreenRecordingStateIfChanged(isActive: false)
     
        let events = dataStore.getAllEvents()
        
        #expect(
            events.map(\.type) == [
                NIDEventName.screenRecordingStarted.rawValue,
                NIDEventName.screenRecordingStopped.rawValue
            ]
        )
        
        #expect(NeuroIDCore.shared.screenCaptureLastKnownState == false)
    }
    
    @Test
    @MainActor
    func startAppEventListeners_screenshotObserverRegisteredOnce() {
        listenerManagerService.startAppEventListeners()
        listenerManagerService.startAppEventListeners()
        listenerManagerService.startAppEventListeners()
        
        // Send screenshot notification
        notificationCenter.post(name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        
        let screenshotEvents = dataStore.getAllEvents().filter {
            $0.type == NIDEventName.screenCapture.rawValue
        }
        
        #expect(screenshotEvents.count == 1)
    }
    
    @Test
    @MainActor
    func stopAppEventListenersRemovesObserver() {

        listenerManagerService.startAppEventListeners()
        listenerManagerService.stopAppEventListeners()
        
        // Send screenshot notification
        notificationCenter.post(name: UIApplication.userDidTakeScreenshotNotification, object: nil)

        let screenshotEvents = dataStore.getAllEvents().filter {
            $0.type == NIDEventName.screenCapture.rawValue
        }
        
        #expect(screenshotEvents.isEmpty)
    }
    
    @available(iOS 17.0, *)
    @Test
    @MainActor
    func sceneDisconnectUpdatesAggregateState() {
        NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID["sceneA"] = NSObject()
        NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID["sceneA"] = true
        NeuroIDCore.shared.screenCaptureLastKnownState = true
        
        listenerManagerService.sceneDidDisconnect(sceneID: "sceneA")
        
        #expect(NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID.isEmpty)
        #expect(NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID.isEmpty)
        #expect(dataStore.getAllEvents().last?.type == NIDEventName.screenRecordingStopped.rawValue)
    }
    
    @available(iOS 17.0, *)
    @Test
    @MainActor
    func observeSceneCaptureEvents_whenAlreadyRegistered_doesNotReEmitRecordingState() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }

        let window = UIWindow(windowScene: scene)
        let controller = UIViewController()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        let sceneID = String(ObjectIdentifier(scene).hashValue)
        NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID[sceneID] = NSObject()
        NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID[sceneID] = true
        NeuroIDCore.shared.screenCaptureLastKnownState = true
        listenerManagerService.observeSceneCaptureEvents(inScreen: controller)
        #expect(
            dataStore.getAllEvents().filter {
                $0.type == NIDEventName.screenRecordingStarted.rawValue
            }.isEmpty
        )
    }
}
