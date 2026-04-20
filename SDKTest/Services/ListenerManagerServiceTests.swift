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
        NeuroIDCore.shared.screenCaptureLastKnownState = nil
        
        self.dataStore = DataStore()
        NeuroIDCore.shared.datastore = dataStore
    }
    
    // MARK: - Screenshot
    
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
    
    // Make sure listeners are removed successfully
    @Test(arguments: [true, false])
    @MainActor
    func stopAppEventListenersRemovesObserver(shouldStart: Bool) {
        if shouldStart {
            listenerManagerService.startAppEventListeners()
        }
        listenerManagerService.stopAppEventListeners()
        
        // Send screenshot notification
        notificationCenter.post(name: UIApplication.userDidTakeScreenshotNotification, object: nil)

        let screenshotEvents = dataStore.getAllEvents().filter {
            $0.type == NIDEventName.screenCapture.rawValue
        }
        
        #expect(screenshotEvents.isEmpty)
    }
    
    // MARK: - Screen Recording
    
    /// First call with isActive=true sets baseline and emits an active event.
    /// Duplicate call with same state is ignored.
    /// State change to false emits an inactive event.
    @Test
    @MainActor
    func updateScreenRecordingStateIfChanged() {
        listenerManagerService.updateScreenRecordingStateIfChanged(isActive: true)
        listenerManagerService.updateScreenRecordingStateIfChanged(isActive: true)  // duplicate — ignored
        listenerManagerService.updateScreenRecordingStateIfChanged(isActive: false)
     
        let events = dataStore.getAllEvents().filter {
            $0.type == NIDEventName.screenRecording.rawValue
        }
        
        #expect(events.count == 2)
        #expect(events[0].attrs == [Attrs(n: "state", v: "active")])
        #expect(events[1].attrs == [Attrs(n: "state", v: "inactive")])
        #expect(NeuroIDCore.shared.screenCaptureLastKnownState == false)
    }
    
    /// First call with isActive=false sets baseline but emits no event (not capturing).
    @Test
    @MainActor
    func updateScreenRecordingStateIfChanged_initialInactive_noEvent() {
        listenerManagerService.updateScreenRecordingStateIfChanged(isActive: false)
        
        let events = dataStore.getAllEvents().filter {
            $0.type == NIDEventName.screenRecording.rawValue
        }
        
        #expect(events.isEmpty)
        #expect(NeuroIDCore.shared.screenCaptureLastKnownState == false)
    }
    
    /// Multiple start/stop cycles each emit an event.
    @Test
    @MainActor
    func screenRecordingStartStopTwice() {
        listenerManagerService.updateScreenRecordingStateIfChanged(isActive: true)
        listenerManagerService.updateScreenRecordingStateIfChanged(isActive: false)
        listenerManagerService.updateScreenRecordingStateIfChanged(isActive: true)
        listenerManagerService.updateScreenRecordingStateIfChanged(isActive: false)
     
        let events = dataStore.getAllEvents().filter {
            $0.type == NIDEventName.screenRecording.rawValue
        }
        
        #expect(events.count == 4)
        #expect(events[0].attrs == [Attrs(n: "state", v: "active")])
        #expect(events[1].attrs == [Attrs(n: "state", v: "inactive")])
        #expect(events[2].attrs == [Attrs(n: "state", v: "active")])
        #expect(events[3].attrs == [Attrs(n: "state", v: "inactive")])
        #expect(NeuroIDCore.shared.screenCaptureLastKnownState == false)
    }
    
    // MARK: - iOS 17 Scene-based Recording
    
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
        
        // After disconnect the aggregate is false → emits inactive event
        let lastEvent = dataStore.getAllEvents().last
        #expect(lastEvent?.type == NIDEventName.screenRecording.rawValue)
        #expect(lastEvent?.attrs == [Attrs(n: "state", v: "inactive")])
    }
    
    @available(iOS 17.0, *)
    @Test
    @MainActor
    func observeSceneCaptureEvents_whenAlreadyRegistered_doesNotReEmitRecordingState() throws {
        withKnownIssue {
            let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
            
            let window = UIWindow(windowScene: scene)
            let controller = UIViewController()
            window.rootViewController = controller
            window.makeKeyAndVisible()
            let sceneID = scene.session.persistentIdentifier
            NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID[sceneID] = NSObject()
            NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID[sceneID] = true
            NeuroIDCore.shared.screenCaptureLastKnownState = true
            listenerManagerService.observeSceneCaptureEvents(inScreen: controller)
            #expect(
                dataStore.getAllEvents().filter {
                    $0.type == NIDEventName.screenRecording.rawValue &&
                    $0.attrs == [Attrs(n: "state", v: "active")]
                }.isEmpty
            )
        }
    }
}
