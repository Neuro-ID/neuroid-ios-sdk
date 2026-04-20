//
//  ListenerManagerService.swift
//  NeuroID
//

import Foundation
import UIKit

@MainActor
protocol ListenerManagerServiceProtocol {
    func startAppEventListeners()
    func stopAppEventListeners()
}

@MainActor
final class ListenerManagerService: ListenerManagerServiceProtocol {

    let notificationCenter: NotificationCenter
    private var appEventObservers: [NSObjectProtocol] = []

    nonisolated init(notificationCenter: NotificationCenter) {
        self.notificationCenter = notificationCenter
    }

    func startAppEventListeners() {
        guard appEventObservers.isEmpty else { return }

        startScreenshotObserver()
        startSceneLifecycleObservers()

        if #available(iOS 17.0, *) {
            registerExistingScenes()
            refreshSceneAggregateRecordingState()
        } else {
            startLegacyScreenRecordingObserver()
            updateScreenRecordingStateIfChanged(isActive: UIScreen.main.isCaptured)
        }
    }

    func stopAppEventListeners() {
        guard !appEventObservers.isEmpty else { return }

        appEventObservers.forEach { notificationCenter.removeObserver($0) }
        appEventObservers.removeAll()

        NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID.removeAll()
        NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID.removeAll()
        NeuroIDCore.shared.screenCaptureLastKnownState = nil
    }
}

// MARK: - Observer Registration
extension ListenerManagerService {
    func startScreenshotObserver() {
        appEventObservers.append(
            notificationCenter.addObserver(
                forName: UIApplication.userDidTakeScreenshotNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.handleScreenshotNotification()
                }
            }
        )
    }

    func startSceneLifecycleObservers() {
        appEventObservers.append(
            notificationCenter.addObserver(
                forName: UIScene.didActivateNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let scene = notification.object as? UIWindowScene else { return }
                Task { @MainActor [weak self] in
                    self?.handleSceneDidActivate(scene)
                }
            }
        )

        appEventObservers.append(
            notificationCenter.addObserver(
                forName: UIScene.didDisconnectNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let scene = notification.object as? UIScene else { return }
                Task { @MainActor [weak self] in
                    self?.handleSceneDidDisconnect(sceneID: scene.session.persistentIdentifier)
                }
            }
        )
    }

    func startLegacyScreenRecordingObserver() {
        appEventObservers.append(
            notificationCenter.addObserver(
                forName: UIScreen.capturedDidChangeNotification,
                object: UIScreen.main,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.handleLegacyScreenCaptureChange(isCaptured: UIScreen.main.isCaptured)
                }
            }
        )
    }
}

// MARK: - Notification Handlers
extension ListenerManagerService {
    func handleScreenshotNotification() {
        captureEvent(event: NIDEvent(type: .screenCapture))
    }

    func handleLegacyScreenCaptureChange(isCaptured: Bool) {
        updateScreenRecordingStateIfChanged(isActive: isCaptured)
    }

    func handleSceneDidActivate(_ scene: UIWindowScene) {
        registerSceneIfNeeded(scene)
    }

    func handleSceneDidDisconnect(sceneID: String) {
        sceneDidDisconnect(sceneID: sceneID)
    }
}

// MARK: - Scene Tracking
extension ListenerManagerService {
    @available(iOS 17.0, *)
    func registerExistingScenes() {
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            registerSceneIfNeeded(scene)
        }
    }

    func registerSceneIfNeeded(_ scene: UIWindowScene) {
        guard #available(iOS 17.0, *) else { return }
        let sceneID = scene.session.persistentIdentifier
        guard NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID[sceneID] == nil else { return }
        NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID[sceneID] = scene.traitCollection.sceneCaptureState == .active
        let registration = scene.registerForTraitChanges([UITraitSceneCaptureState.self]) {
            [weak self] (windowScene: UIWindowScene, _: UITraitCollection) in
            let changedSceneID = windowScene.session.persistentIdentifier
            let isActive = windowScene.traitCollection.sceneCaptureState == .active
            Task { @MainActor [weak self] in
                self?.handleSceneCaptureTraitChange(sceneID: changedSceneID, isActive: isActive)
            }
        }
        NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID[sceneID] = registration as AnyObject
        refreshSceneAggregateRecordingState()
    }

    @available(iOS 17.0, *)
    func handleSceneCaptureTraitChange(sceneID: String, isActive: Bool) {
        NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID[sceneID] = isActive
        refreshSceneAggregateRecordingState()
    }

    func sceneDidDisconnect(sceneID: String) {
        if #available(iOS 17.0, *) {
            NeuroIDCore.shared.sceneCaptureRegistrationsBySceneID.removeValue(forKey: sceneID)
            NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID.removeValue(forKey: sceneID)
            refreshSceneAggregateRecordingState()
        }
    }
}

// MARK: - Screen Recording State
extension ListenerManagerService {
    func updateScreenRecordingStateIfChanged(isActive: Bool) {
        let event = NIDEvent(type: .screenRecording)
        if NeuroIDCore.shared.screenCaptureLastKnownState == nil {
            NeuroIDCore.shared.screenCaptureLastKnownState = isActive
            if isActive {
                event.attrs = [Attrs(n: "state", v: "active")]
                captureEvent(event: event)
            }
            return
        }
        guard NeuroIDCore.shared.screenCaptureLastKnownState != isActive else { return }
        NeuroIDCore.shared.screenCaptureLastKnownState = isActive
        event.attrs = [Attrs(n: "state", v: isActive ? "active" : "inactive")]
        captureEvent(event: event)
    }

    @available(iOS 17.0, *)
    func refreshSceneAggregateRecordingState() {
        let isActive = NeuroIDCore.shared.sceneCaptureLastKnownStateBySceneID.values.contains(true)
        updateScreenRecordingStateIfChanged(isActive: isActive)
    }
}

// MARK: - Event Capture
extension ListenerManagerService {
    fileprivate func captureEvent(event: NIDEvent) {
        event.url = NeuroID.getScreenName()
        NeuroIDCore.shared.saveEventToLocalDataStore(
            event,
            screen: NeuroID.getScreenName() ?? ParamsCreator.generateID()
        )
    }
}
