//
//  ListenerManagerService.swift
//  NeuroID
//

import Foundation
import UIKit

protocol ListenerManagerServiceProtocol {
    @MainActor
    func startAppEventListeners()
    @MainActor
    func stopAppEventListeners()
    @MainActor
    func observeSceneCaptureEvents(inScreen controller: UIViewController?)
}

final class ListenerManagerService: ListenerManagerServiceProtocol {
    
    let notificationCenter: NotificationCenter
    private var appEventObservers: [NSObjectProtocol]
    
    init(notificationCenter: NotificationCenter) {
        self.notificationCenter = notificationCenter
        self.appEventObservers = []
    }
    
    // Attach listeners to notification center events
    @MainActor
    func startAppEventListeners() {
        guard appEventObservers.isEmpty else { return }

        // Screen Capture (screenshot) Observer
        appEventObservers.append(
            notificationCenter.addObserver(
                forName: UIApplication.userDidTakeScreenshotNotification,
                object: nil,
                queue: .main
            ) { message in
                ListenerManagerService.captureEvent(event: .screenCapture)
            }
        )

        // Screen Recording Events for <iOS 17.0
        if #unavailable(iOS 17.0) {
            appEventObservers.append(
                notificationCenter.addObserver(
                    forName: UIScreen.capturedDidChangeNotification,
                    object: UIScreen.main,
                    queue: .main
                ) { message in
                    self.updateScreenRecordingStateIfChanged(isActive: UIScreen.main.isCaptured)
                }
            )

            updateScreenRecordingStateIfChanged(isActive: UIScreen.main.isCaptured)
        }
        
        // Handles scene disconnects for iOS 17.0+
        if #available(iOS 17.0, *) {
            appEventObservers.append(
                notificationCenter.addObserver(
                    forName: UIScene.didDisconnectNotification,
                    object: nil,
                    queue: .main
                ) { notification in
                    guard let scene = notification.object as? UIScene else { return }
                    self.sceneDidDisconnect(sceneID: scene.session.persistentIdentifier)
                }
            )
            performInitialSceneCaptureCheck()
        }
    }

    @MainActor
    func stopAppEventListeners() {
        guard !appEventObservers.isEmpty else { return }
        appEventObservers.forEach { notificationCenter.removeObserver($0) }
        appEventObservers.removeAll()
    }

    // Start observing events at the view controller
    @MainActor
    func observeSceneCaptureEvents(inScreen controller: UIViewController?) {
        guard #available(iOS 17.0, *), let scene = controller?.viewIfLoaded?.window?.windowScene else { return }

        let sceneID = scene.session.persistentIdentifier
        
        if NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID[sceneID] == nil {
            NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID[sceneID] = scene.traitCollection.sceneCaptureState == .active

            let registration = scene.registerForTraitChanges([UITraitSceneCaptureState.self]) {
                [weak self] (windowScene: UIWindowScene, previousTraitCollection: UITraitCollection) in
                self?.updateSceneCaptureState(
                    sceneID: windowScene.session.persistentIdentifier,
                    isActive: windowScene.traitCollection.sceneCaptureState == .active
                )
            }
            NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID[sceneID] = registration as AnyObject
        }
    }

    func updateScreenRecordingStateIfChanged(isActive: Bool) {
        if NeuroIDCore.shared.screenCaptureLastKnownState == nil {
            NeuroIDCore.shared.screenCaptureLastKnownState = isActive
            if isActive {
                ListenerManagerService.captureEvent(event: .screenRecordingStarted)
            }
            return
        }

        guard NeuroIDCore.shared.screenCaptureLastKnownState != isActive else { return }
        NeuroIDCore.shared.screenCaptureLastKnownState = isActive
        ListenerManagerService.captureEvent(event: isActive ? .screenRecordingStarted : .screenRecordingStopped)
    }

    @available(iOS 17.0, *)
    private func updateSceneCaptureState(sceneID: String, isActive: Bool) {
        NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID[sceneID] = isActive
        refreshSceneAggregateRecordingState()
    }

    @available(iOS 17.0, *)
    func sceneDidDisconnect(sceneID: String) {
        NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID.removeValue(forKey: sceneID)
        NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID.removeValue(forKey: sceneID)
        refreshSceneAggregateRecordingState()
    }

    @available(iOS 17.0, *)
    func refreshSceneAggregateRecordingState() {
        let isActive = NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID.values.contains(true)
        updateScreenRecordingStateIfChanged(isActive: isActive)
    }
    
    @available(iOS 17.0, *)
    @MainActor
    func performInitialSceneCaptureCheck() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            let sceneID = scene.session.persistentIdentifier
            NeuroIDCore.shared
                .sceneCaptureLastKnownStateBySceneID[sceneID] = scene.traitCollection.sceneCaptureState == .active
        }
        refreshSceneAggregateRecordingState()
    }

    
    private static func captureEvent(event: NIDEventName) {
        let event = NIDEvent(type: event, url: NeuroID.getScreenName())
        NeuroIDCore.shared.saveEventToLocalDataStore(event, screen: NeuroID.getScreenName() ?? ParamsCreator.generateID())
    }
}
