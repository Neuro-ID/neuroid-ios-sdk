//
//  NIDStatic.swift
//  NeuroID
//
//  Created by Kevin Sites on 8/19/25.
//

import UIKit

// All Static Methods that need to be available for integrations will be available
//  in this file. Internally all of them will call the class instance method.

public enum NeuroID {
    
    static func configure(_ configuration: NeuroID.Configuration) -> Bool {
        return NeuroIDCore.shared.configure(configuration)
    }
    
    @available(*, deprecated, renamed: "configure(_:)", message: "Use `NeuroID.configure(_ configuration: NeuroID.Configuration)` instead.")
    static func configure(
        clientKey: String, isAdvancedDevice: Bool = false, advancedDeviceKey: String? = nil
    ) -> Bool {
        let configuration = NeuroID.Configuration(
            clientKey: clientKey,
            isAdvancedDevice: isAdvancedDevice,
            advancedDeviceKey: advancedDeviceKey
        )
        return NeuroIDCore.shared.configure(configuration)
    }

    static func enableLogging(_ value: Bool) {
        NeuroIDCore.shared.enableLogging(value)
    }

    static func getSDKVersion() -> String {
        return NeuroIDCore.shared.getSDKVersion()
    }

    static func isStopped() -> Bool {
        return NeuroIDCore.shared.isStopped()
    }

    static func getEnvironment() -> String {
        return NeuroIDCore.shared.getEnvironment()
    }

    static func getScreenName() -> String? {
        return NeuroIDCore.shared.getScreenName()
    }

    static func setScreenName(_ screen: String) -> Bool {
        return NeuroIDCore.shared.setScreenName(screen)
    }

    static func getClientID() -> String {
        return NeuroIDCore.shared.getClientID()
    }

    @available(*, deprecated, message: "setSiteId is deprecated and no longer required")
    static func setSiteId(siteId: String) {
        NeuroIDCore.shared.setSiteId(siteId: siteId)
    }

    // Functions do the same thing, but call signature is different
    static func excludeViewByTestID(_ excludedView: String) {
        NeuroIDCore.shared.excludeViewByTestID(excludedView)
    }

    @available(*, deprecated, message: "excludeViewByTestID(excludedView: String) is deprecated, please use `excludeViewByTestID(_ excludedView: String)` instead.")
    static func excludeViewByTestID(excludedView: String) {
        NeuroIDCore.shared.excludeViewByTestID(excludedView)
    }

    @available(*, deprecated, message: "setCustomVariable is deprecated, use `setVariable` instead")
    static func setCustomVariable(key: String, v: String) -> NIDEvent {
        NeuroIDCore.shared.setVariable(key: key, value: v)
    }

    static func setVariable(key: String, value: String) -> NIDEvent {
        NeuroIDCore.shared.setVariable(key: key, value: value)
    }

    // USER FUNCTIONS
    // This command replaces `setUserID`
    // Formerly known as userID, now within the mobile sdk ONLY sessionID
    static func identify(_ sessionID: String) -> Bool {
        return NeuroIDCore.shared.identify(sessionID)
    }

    // Temporarily keeping this function for backwards compatibility
    @available(*, deprecated, message: "setUserID is deprecated, please use `identify` instead.")
    static func setUserID(_ userID: String) -> Bool {
        return NeuroIDCore.shared.identify(userID)
    }

    static func getSessionID() -> String {
        return NeuroIDCore.shared.getSessionID()
    }

    //  Temporarily keeping this function for backwards compatibility, will be removed
    // replaced with`getSessionID`
    @available(*, deprecated, message: "getUserID is deprecated, please use `getSessionID` instead.")
    static func getUserID() -> String {
        return NeuroIDCore.shared.getSessionID()
    }

    static func setRegisteredUserID(_ registeredUserID: String) -> Bool {
        return NeuroIDCore.shared.setRegisteredUserID(registeredUserID)
    }

    static func getRegisteredUserID() -> String {
        return NeuroIDCore.shared.getRegisteredUserID()
    }

    /**
     This should be called the moment a user trys to login. Returns true always
     @param {String} [attemptedRegisteredUserId] - an optional identifier for the login
     */
    static func attemptedLogin(_ attemptedRegisteredUserId: String? = nil) -> Bool {
        return NeuroIDCore.shared.attemptedLogin(attemptedRegisteredUserId)
    }

    // SESSION FUNCTIONS
    static func start(
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        NeuroIDCore.shared.start(siteID: nil, completion: completion)
    }

    static func stop() -> Bool {
        return NeuroIDCore.shared.stop()
    }

    static func startSession(
        _ sessionID: String? = nil,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        NeuroIDCore.shared.startSession(siteID: nil, sessionID: sessionID, completion: completion)
    }

    static func pauseCollection() {
        NeuroIDCore.shared.saveEventToLocalDataStore(
            NIDEvent.createInfoLogEvent("pause collection attempt")
        )
        NeuroIDCore.shared.pauseCollection(flushEventQueue: true)
    }

    static func resumeCollection() {
        NeuroIDCore.shared.resumeCollection()
    }

    static func stopSession() -> Bool {
        return NeuroIDCore.shared.stopSession()
    }

    /*
      Function to allow multiple use cases/flows within a single application
      Can be used as the original starting function and then use continuously
       throughout the rest of the session
      i.e. start/startSession/startAppFlow -> startAppFlow("site2") -> stop/stopSession
     */
    static func startAppFlow(
        siteID: String,
        sessionID: String? = nil,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        NeuroIDCore.shared.startAppFlow(siteID: siteID, sessionID: sessionID, completion: completion)
    }

    // AdvancedDevice Functions
    static func start(
        _ advancedDeviceSignals: Bool,
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        NeuroIDCore.shared.start(advancedDeviceSignals, completion: completion)
    }

    static func startSession(
        _ sessionID: String? = nil,
        _ advancedDeviceSignals: Bool,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        NeuroIDCore.shared.startSession(sessionID, advancedDeviceSignals, completion: completion)
    }

    // RN Functions
    static func configure(clientKey: String, rnOptions: [String: Any]) -> Bool {
        return NeuroIDCore.shared.configure(clientKey: clientKey, rnOptions: rnOptions)
    }

    static func registerPageTargets() {
        NeuroIDCore.shared.registerPageTargets()
    }

    /** Public API for manually registering a target. This should only be used when automatic fails. */
    @available(*, deprecated, message: "manuallyRegisterTarget is deprecated and no longer used")
    static func manuallyRegisterTarget(view: UIView) {
        NeuroIDCore.shared.manuallyRegisterTarget(view: view)
    }

    /** React Native API for manual registration - DEPRECATED */
    @available(*, deprecated, message: "manuallyRegisterRNTarget is deprecated and no longer used")
    static func manuallyRegisterRNTarget(
        id: String,
        className: String,
        screenName: String,
        placeHolder: String
    ) -> NIDEvent {
        return NeuroIDCore.shared.manuallyRegisterRNTarget(
            id: id, className:
            className,
            screenName: screenName,
            placeHolder: placeHolder
        )
    }
}
