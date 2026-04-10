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
    private var appEventObservers: [NSObjectProtocol] = []

    @MainActor
    func startAppEventListeners() {
        guard appEventObservers.isEmpty else { return }

        // Screenshot Observer
        appEventObservers.append(
            NotificationCenter.default.addObserver(
                forName: UIApplication.userDidTakeScreenshotNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.captureEvent(event: .screenCapture)
            }
        )

        // Screen Recording Events for <iOS 17.0
        if #unavailable(iOS 17.0) {
            appEventObservers.append(
                NotificationCenter.default.addObserver(
                    forName: UIScreen.capturedDidChangeNotification,
                    object: UIScreen.main,
                    queue: .main
                ) { [weak self] _ in
                    self?.updateScreenRecordingStateIfChanged(isActive: UIScreen.main.isCaptured)
                }
            )

            updateScreenRecordingStateIfChanged(isActive: UIScreen.main.isCaptured)
        } else {
            appEventObservers.append(
                NotificationCenter.default.addObserver(
                    forName: UIScene.didDisconnectNotification,
                    object: nil,
                    queue: .main
                ) { [weak self] notification in
                    guard let scene = notification.object as? UIScene else { return }
                    self?.sceneDidDisconnect(sceneID: scene.session.persistentIdentifier)
                }
            )
            performInitialSceneCaptureCheck()
        }
    }

    @MainActor
    func stopAppEventListeners() {
        guard !appEventObservers.isEmpty else { return }
        appEventObservers.forEach { NotificationCenter.default.removeObserver($0) }
        appEventObservers.removeAll()
    }

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
                captureEvent(event: .screenRecordingStarted)
            }
            return
        }

        guard NeuroIDCore.shared.screenCaptureLastKnownState != isActive else { return }
        NeuroIDCore.shared.screenCaptureLastKnownState = isActive
        captureEvent(event: isActive ? .screenRecordingStarted : .screenRecordingStopped)
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
    func performInitialSceneCaptureCheck() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            let sceneID = scene.session.persistentIdentifier
            NeuroIDCore.shared
                .sceneCaptureLastKnownStateBySceneID[sceneID] = scene.traitCollection.sceneCaptureState == .active
        }
        refreshSceneAggregateRecordingState()
    }

    private func captureEvent(event: NIDEventName) {
        let event = NIDEvent(type: event, url: NeuroID.getScreenName())
        NeuroIDCore.shared.saveEventToLocalDataStore(event, screen: NeuroID.getScreenName() ?? ParamsCreator.generateID())
    }
}
