//
//  NIDStatic.swift
//  NeuroID
//
//  Created by Kevin Sites on 8/19/25.
//

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

    static func getClientID() -> String {
        return NeuroID.shared.getClientID()
    }

    @available(*, deprecated, message: "setSiteId is deprecated and no longer required")
    static func setSiteId(siteId: String) {
        NeuroID.shared.setSiteId(siteId: siteId)
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

    // SESSION FUNCTIONS
    static func stop() -> Bool {
        return NeuroID.shared.stop()
    }
}
