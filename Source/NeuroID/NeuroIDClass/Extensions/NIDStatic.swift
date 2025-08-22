//
//  NIDStatic.swift
//  NeuroID
//
//  Created by Kevin Sites on 8/19/25.
//

import UIKit

// All Static Methods that need to be available for integrations will be available
//  in this file. Internally all of them will call the class instance method.

public extension NeuroID {
    static func enableLogging(_ value: Bool) {
        NeuroID.shared.enableLogging(value)
    }

    static func getSDKVersion() -> String {
        return NeuroID.shared.getSDKVersion()
    }

    static func isStopped() -> Bool {
        return NeuroID.shared.isStopped()
    }

    static func getEnvironment() -> String {
        return NeuroID.shared.getEnvironment()
    }

    static func getScreenName() -> String? {
        return NeuroID.shared.getScreenName()
    }

    static func setScreenName(_ screen: String) -> Bool {
        return NeuroID.shared.setScreenName(screen)
    }

    static func getClientID() -> String {
        return NeuroID.shared.getClientID()
    }

    @available(*, deprecated, message: "setSiteId is deprecated and no longer required")
    static func setSiteId(siteId: String) {
        NeuroID.shared.setSiteId(siteId: siteId)
    }

    // Functions do the same thing, but call signature is different
    static func excludeViewByTestID(_ excludedView: String) {
        NeuroID.shared.excludeViewByTestID(excludedView)
    }

    @available(*, deprecated, message: "excludeViewByTestID(excludedView: String) is deprecated, please use `excludeViewByTestID(_ excludedView: String)` instead.")
    static func excludeViewByTestID(excludedView: String) {
        NeuroID.shared.excludeViewByTestID(excludedView)
    }

    @available(*, deprecated, message: "setCustomVariable is deprecated, use `setVariable` instead")
    static func setCustomVariable(key: String, v: String) -> NIDEvent {
        NeuroID.shared.setVariable(key: key, value: v)
    }

    static func setVariable(key: String, value: String) -> NIDEvent {
        NeuroID.shared.setVariable(key: key, value: value)
    }

    // USER FUNCTIONS
    // This command replaces `setUserID`
    // Formerly known as userID, now within the mobile sdk ONLY sessionID
    static func identify(_ sessionID: String) -> Bool {
        return NeuroID.shared.identify(sessionID)
    }

    // Temporarily keeping this function for backwards compatibility
    @available(*, deprecated, message: "setUserID is deprecated, please use `identify` instead.")
    static func setUserID(_ userID: String) -> Bool {
        return NeuroID.shared.identify(userID)
    }

    static func getSessionID() -> String {
        return NeuroID.shared.getSessionID()
    }

    //  Temporarily keeping this function for backwards compatibility, will be removed
    // replaced with`getSessionID`
    @available(*, deprecated, message: "getUserID is deprecated, please use `getSessionID` instead.")
    static func getUserID() -> String {
        return NeuroID.getSessionID()
    }

    static func setRegisteredUserID(_ registeredUserID: String) -> Bool {
        return NeuroID.shared.setRegisteredUserID(registeredUserID)
    }

    static func getRegisteredUserID() -> String {
        return NeuroID.shared.getRegisteredUserID()
    }

    /**
     This should be called the moment a user trys to login. Returns true always
     @param {String} [attemptedRegisteredUserId] - an optional identifier for the login
     */
    static func attemptedLogin(_ attemptedRegisteredUserId: String? = nil) -> Bool {
        return NeuroID.shared.attemptedLogin(attemptedRegisteredUserId)
    }

    // SESSION FUNCTIONS
    static func start(
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        NeuroID.shared.start(siteID: nil, completion: completion)
    }

    static func stop() -> Bool {
        return NeuroID.shared.stop()
    }

    static func startSession(
        _ sessionID: String? = nil,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        NeuroID.shared.startSession(siteID: nil, sessionID: sessionID, completion: completion)
    }

    static func pauseCollection() {
        NeuroID.shared.saveEventToLocalDataStore(
            NIDEvent.createInfoLogEvent("pause collection attempt")
        )
        NeuroID.shared.pauseCollection(flushEventQueue: true)
    }

    static func resumeCollection() {
        NeuroID.shared.resumeCollection()
    }

    static func stopSession() -> Bool {
        return NeuroID.shared.stopSession()
    }

    // RN Functions
    static func registerPageTargets() {
        NeuroID.shared.registerPageTargets()
    }

    /** Public API for manually registering a target. This should only be used when automatic fails. */
    @available(*, deprecated, message: "manuallyRegisterTarget is deprecated and no longer used")
    static func manuallyRegisterTarget(view: UIView) {
        NeuroID.shared.manuallyRegisterTarget(view: view)
    }

    /** React Native API for manual registration - DEPRECATED */
    @available(*, deprecated, message: "manuallyRegisterRNTarget is deprecated and no longer used")
    static func manuallyRegisterRNTarget(
        id: String,
        className: String,
        screenName: String,
        placeHolder: String
    ) -> NIDEvent {
        return NeuroID.shared.manuallyRegisterRNTarget(
            id: id, className:
            className,
            screenName: screenName,
            placeHolder: placeHolder
        )
    }
}
