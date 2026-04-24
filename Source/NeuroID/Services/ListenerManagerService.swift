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

    let uiRuntime: UIRuntime
    let notificationCenter: NotificationCenter
    private var appEventObservers: [NSObjectProtocol] = []

    nonisolated init(uiRuntime: UIRuntime, notificationCenter: NotificationCenter) {
        self.uiRuntime = uiRuntime
        self.notificationCenter = notificationCenter
    }

    func startAppEventListeners() {
        guard appEventObservers.isEmpty else { return }

        startScreenshotObserver()
        startSceneLifecycleObservers()

        if #available(iOS 17.0, *) {
            // UIScreen.capturedDidChangeNotification is deprecated in iOS 17+, replaced by per-scene trait callbacks
            // connected scenes won't fire didActivate, so seed their state before computing the initial aggregate
            registerExistingScenes()
            refreshSceneAggregateRecordingState()
        } else {
            startLegacyScreenRecordingObserver()
            // notification won't fire if recording was already active when the SDK starts
            updateScreenRecordingStateIfChanged(isActive: UIScreen.main.isCaptured)
        }
    }

    func stopAppEventListeners() {
        guard !appEventObservers.isEmpty else { return }

        for observer in appEventObservers {
            notificationCenter.removeObserver(observer)
        }
        appEventObservers.removeAll()

        uiRuntime.resetScreenCaptureTrackingState()
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
        // also fires on foreground return, catching scenes not present at SDK start
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

        // prevents stale scene entries from holding aggregate state as "active"
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
        guard uiRuntime.sceneCaptureRegistrationsBySceneID[sceneID] == nil else { return }
        uiRuntime.sceneCaptureLastKnownStateBySceneID[sceneID] = scene.traitCollection.sceneCaptureState == .active
        // iOS 17+ replacement for the deprecated traitCollectionDidChange override
        let registration = scene.registerForTraitChanges([UITraitSceneCaptureState.self]) {
            [weak self] (windowScene: UIWindowScene, _: UITraitCollection) in
            let changedSceneID = windowScene.session.persistentIdentifier
            let isActive = windowScene.traitCollection.sceneCaptureState == .active
            Task { @MainActor [weak self] in
                self?.handleSceneCaptureTraitChange(sceneID: changedSceneID, isActive: isActive)
            }
        }
        uiRuntime.sceneCaptureRegistrationsBySceneID[sceneID] = registration as AnyObject
        refreshSceneAggregateRecordingState()
    }

    @available(iOS 17.0, *)
    func handleSceneCaptureTraitChange(sceneID: String, isActive: Bool) {
        uiRuntime.sceneCaptureLastKnownStateBySceneID[sceneID] = isActive
        refreshSceneAggregateRecordingState()
    }

    func sceneDidDisconnect(sceneID: String) {
        if #available(iOS 17.0, *) {
            uiRuntime.sceneCaptureRegistrationsBySceneID.removeValue(forKey: sceneID)
            uiRuntime.sceneCaptureLastKnownStateBySceneID.removeValue(forKey: sceneID)
            refreshSceneAggregateRecordingState()
        }
    }
}

// MARK: - Screen Recording State
extension ListenerManagerService {
    func updateScreenRecordingStateIfChanged(isActive: Bool) {
        var event = NIDEvent(type: .screenRecording)
        if uiRuntime.screenCaptureLastKnownState == nil {
            // first observation — only emit if already active to avoid a spurious "inactive" on cold start
            uiRuntime.screenCaptureLastKnownState = isActive
            if isActive {
                event.attrs = [Attrs(n: "state", v: "active")]
                captureEvent(event: event)
            }
            return
        }
        // dedupe — multiple scenes can converge on the same state
        guard uiRuntime.screenCaptureLastKnownState != isActive else { return }
        uiRuntime.screenCaptureLastKnownState = isActive
        event.attrs = [Attrs(n: "state", v: isActive ? "active" : "inactive")]
        captureEvent(event: event)
    }

    @available(iOS 17.0, *)
    func refreshSceneAggregateRecordingState() {
        // any one scene capturing = device is recording
        let isActive = uiRuntime.sceneCaptureLastKnownStateBySceneID.values.contains(true)
        updateScreenRecordingStateIfChanged(isActive: isActive)
    }
}

// MARK: - Event Capture
extension ListenerManagerService {
    fileprivate func captureEvent(event: NIDEvent) {
        var event = event
        event.url = NeuroID.getScreenName()
        NeuroIDCore.shared.saveEventToLocalDataStore(
            event,
            screen: NeuroID.getScreenName() ?? ParamsCreator.generateID()
        )
    }
}
