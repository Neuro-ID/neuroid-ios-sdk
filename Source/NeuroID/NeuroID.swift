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

    // Functions do the same thing, but call signature is different
    public static func excludeViewByTestID(_ excludedView: String) {
        NeuroIDCore.shared.excludeViewByTestID(excludedView)
    }

    public static func setVariable(key: String, value: String) -> NIDEvent {
        NeuroIDCore.shared.setVariable(key: key, value: value)
    }

    // Identity ID

    public static func getIdentityId() -> String {
        return NeuroIDCore.shared.getIdentityId()
    }

    public static func identify(_ identityId: String) -> Bool {
        return NeuroIDCore.shared.identify(identityId)
    }

    // Registered User ID

    public static func setRegisteredUserID(_ registeredUserID: String) -> Bool {
        return NeuroIDCore.shared.setRegisteredUserID(registeredUserID)
    }

    public static func getRegisteredUserID() -> String {
        return NeuroIDCore.shared.getRegisteredUserID()
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
        _ identityId: String? = nil,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        NeuroIDCore.shared.startSession(siteID: nil, identityId: identityId, completion: completion)
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
    @available(*, deprecated)
    public static func startAppFlow(
        siteID: String,
        sessionID: String? = nil,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        NeuroIDCore.shared.startAppFlow(siteID: siteID, identityId: sessionID, completion: completion)
    }

    // RN Functions
    public static func configure(clientKey: String, rnOptions: [String: Any]) -> Bool {
        return NeuroIDCore.shared.configure(clientKey: clientKey, rnOptions: rnOptions)
    }

    public static func registerPageTargets() {
        NeuroIDCore.shared.registerPageTargets()
    }
}
