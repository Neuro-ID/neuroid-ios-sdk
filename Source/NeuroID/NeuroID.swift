//
//  NeuroID.swift
//  NeuroID
//
//  Created by Kevin Sites on 8/19/25.
//

import UIKit

// All Static Methods that need to be available for integrations will be available
//  in this file. Internally all of them will call the class instance method.

public enum NeuroID {
    
    public static func configure(_ configuration: NeuroID.Configuration) -> Bool {
        return NeuroIDCore.shared.configure(configuration)
    }
    
    @available(*, deprecated, renamed: "configure(_:)", message: "Use `NeuroID.configure(_ configuration: NeuroID.Configuration)` instead.")
    public static func configure(
        clientKey: String, isAdvancedDevice: Bool = false, advancedDeviceKey: String? = nil
    ) -> Bool {
        let configuration = NeuroID.Configuration(
            clientKey: clientKey,
            isAdvancedDevice: isAdvancedDevice,
            advancedDeviceKey: advancedDeviceKey
        )
        return NeuroIDCore.shared.configure(configuration)
    }

    public static func enableLogging(_ value: Bool) {
        NeuroIDCore.shared.enableLogging(value)
    }

    public static func getSDKVersion() -> String {
        return NeuroIDCore.shared.getSDKVersion()
    }

    public static func isStopped() -> Bool {
        return NeuroIDCore.shared.isStopped()
    }

    public static func getEnvironment() -> String {
        return NeuroIDCore.shared.getEnvironment()
    }

    public static func getScreenName() -> String? {
        return NeuroIDCore.shared.getScreenName()
    }

    public static func setScreenName(_ screen: String) -> Bool {
        return NeuroIDCore.shared.setScreenName(screen)
    }

    public static func getClientID() -> String {
        return NeuroIDCore.shared.getClientID()
    }

    @available(*, deprecated, message: "setSiteId is deprecated and no longer required")
    public static func setSiteId(siteId: String) {
        NeuroIDCore.shared.setSiteId(siteId: siteId)
    }

    // Functions do the same thing, but call signature is different
    public static func excludeViewByTestID(_ excludedView: String) {
        NeuroIDCore.shared.excludeViewByTestID(excludedView)
    }

    @available(*, deprecated, message: "excludeViewByTestID(excludedView: String) is deprecated, please use `excludeViewByTestID(_ excludedView: String)` instead.")
    public static func excludeViewByTestID(excludedView: String) {
        NeuroIDCore.shared.excludeViewByTestID(excludedView)
    }

    @available(*, deprecated, message: "setCustomVariable is deprecated, use `setVariable` instead")
    public static func setCustomVariable(key: String, v: String) -> NIDEvent {
        NeuroIDCore.shared.setVariable(key: key, value: v)
    }

    public static func setVariable(key: String, value: String) -> NIDEvent {
        NeuroIDCore.shared.setVariable(key: key, value: value)
    }

    // USER FUNCTIONS
    // This command replaces `setUserID`
    // Formerly known as userID, now within the mobile sdk ONLY sessionID
    public static func identify(_ sessionID: String) -> Bool {
        return NeuroIDCore.shared.identify(sessionID)
    }

    // Temporarily keeping this function for backwards compatibility
    @available(*, deprecated, message: "setUserID is deprecated, please use `identify` instead.")
    public static func setUserID(_ userID: String) -> Bool {
        return NeuroIDCore.shared.identify(userID)
    }

    public static func getSessionID() -> String {
        return NeuroIDCore.shared.getSessionID()
    }

    //  Temporarily keeping this function for backwards compatibility, will be removed
    // replaced with`getSessionID`
    @available(*, deprecated, message: "getUserID is deprecated, please use `getSessionID` instead.")
    public static func getUserID() -> String {
        return NeuroIDCore.shared.getSessionID()
    }

    public static func setRegisteredUserID(_ registeredUserID: String) -> Bool {
        return NeuroIDCore.shared.setRegisteredUserID(registeredUserID)
    }

    public static func getRegisteredUserID() -> String {
        return NeuroIDCore.shared.getRegisteredUserID()
    }

    /**
     This should be called the moment a user trys to login. Returns true always
     @param {String} [attemptedRegisteredUserId] - an optional identifier for the login
     */
    public static func attemptedLogin(_ attemptedRegisteredUserId: String? = nil) -> Bool {
        return NeuroIDCore.shared.attemptedLogin(attemptedRegisteredUserId)
    }

    // SESSION FUNCTIONS
    public static func start(
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        NeuroIDCore.shared.start(siteID: nil, completion: completion)
    }

    public static func stop() -> Bool {
        return NeuroIDCore.shared.stop()
    }

    public static func startSession(
        _ sessionID: String? = nil,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        NeuroIDCore.shared.startSession(siteID: nil, sessionID: sessionID, completion: completion)
    }

    public static func pauseCollection() {
        NeuroIDCore.shared.saveEventToLocalDataStore(
            NIDEvent.createInfoLogEvent("pause collection attempt")
        )
        NeuroIDCore.shared.pauseCollection(flushEventQueue: true)
    }

    public static func resumeCollection() {
        NeuroIDCore.shared.resumeCollection()
    }

    public static func stopSession() -> Bool {
        return NeuroIDCore.shared.stopSession()
    }

    /*
      Function to allow multiple use cases/flows within a single application
      Can be used as the original starting function and then use continuously
       throughout the rest of the session
      i.e. start/startSession/startAppFlow -> startAppFlow("site2") -> stop/stopSession
     */
    public static func startAppFlow(
        siteID: String,
        sessionID: String? = nil,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        NeuroIDCore.shared.startAppFlow(siteID: siteID, sessionID: sessionID, completion: completion)
    }

    // AdvancedDevice Functions
    public static func start(
        _ advancedDeviceSignals: Bool,
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        NeuroIDCore.shared.start(advancedDeviceSignals, completion: completion)
    }

    public static func startSession(
        _ sessionID: String? = nil,
        _ advancedDeviceSignals: Bool,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        NeuroIDCore.shared.startSession(sessionID, advancedDeviceSignals, completion: completion)
    }

    // RN Functions
    public static func configure(clientKey: String, rnOptions: [String: Any]) -> Bool {
        return NeuroIDCore.shared.configure(clientKey: clientKey, rnOptions: rnOptions)
    }

    public static func registerPageTargets() {
        NeuroIDCore.shared.registerPageTargets()
    }

    /** Public API for manually registering a target. This should only be used when automatic fails. */
    @available(*, deprecated, message: "manuallyRegisterTarget is deprecated and no longer used")
    public static func manuallyRegisterTarget(view: UIView) {
        NeuroIDCore.shared.manuallyRegisterTarget(view: view)
    }

    /** React Native API for manual registration - DEPRECATED */
    @available(*, deprecated, message: "manuallyRegisterRNTarget is deprecated and no longer used")
    public static func manuallyRegisterRNTarget(
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

    // ENG-9193 - Will remove on next breaking release
    @available(
        *, deprecated,
        message: "printIntegrationHealthInstruction is deprecated and no longer functional"
    )
    public static func printIntegrationHealthInstruction() {
        NIDLog.info("**** NOTE: THIS METHOD IS DEPRECATED AND IS NO LONGER FUNCTIONAL")
    }

    // ENG-9193 - Will remove on next breaking release
    @available(
        *, deprecated,
        message: "printIntegrationHealthInstruction is deprecated and no longer functional"
    )
    public static func setVerifyIntegrationHealth(_ verify: Bool) {
        NIDLog.info("**** NOTE: THIS METHOD IS DEPRECATED AND IS NO LONGER FUNCTIONAL")
    }

    /**
     Form Submit, Sccuess & Failure
     */
    @available(*, deprecated, message: "formSubmit is deprecated and no longer required")
    public static func formSubmit() -> NIDEvent {
        let submitEvent = NIDEvent(type: NIDEventName.applicationSubmit)
        NeuroIDCore.shared.saveEventToLocalDataStore(submitEvent)
        NIDLog.info("**** NOTE: THIS METHOD IS DEPRECATED AND IS NO LONGER REQUIRED")
        return submitEvent
    }

    @available(*, deprecated, message: "formSubmitFailure is deprecated and no longer required")
    public static func formSubmitFailure() -> NIDEvent {
        let submitEvent = NIDEvent(type: NIDEventName.applicationSubmitFailure)
        NeuroIDCore.shared.saveEventToLocalDataStore(submitEvent)
        NIDLog.info("**** NOTE: THIS METHOD IS DEPRECATED AND IS NO LONGER REQUIRED")
        return submitEvent
    }

    @available(*, deprecated, message: "formSubmitSuccess is deprecated and no longer required")
    public static func formSubmitSuccess() -> NIDEvent {
        let submitEvent = NIDEvent(type: NIDEventName.applicationSubmitSuccess)
        NeuroIDCore.shared.saveEventToLocalDataStore(submitEvent)
        NIDLog.info("**** NOTE: THIS METHOD IS DEPRECATED AND IS NO LONGER REQUIRED")
        return submitEvent
    }

    @available(*, deprecated, message: "setEnvironmentProduction is deprecated and no longer required")
    public static func setEnvironmentProduction(_ value: Bool) {
        NIDLog.info("**** NOTE: THIS METHOD IS DEPRECATED")
    }
}
