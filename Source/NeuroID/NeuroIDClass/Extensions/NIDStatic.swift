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

    // Static method for backward compatibility
    static func getEnvironment() -> String {
        return NeuroID.shared.getEnvironment()
    }

    // Static method for backward compatibility
    static func getScreenName() -> String? {
        return NeuroID.shared.getScreenName()
    }

    // USER FUNCTIONS
    // This command replaces `setUserID`
    // Formerly known as userID, now within the mobile sdk ONLY sessionID
    static func identify(_ sessionID: String) -> Bool {
        return NeuroID.shared.identify(sessionID)
    }

    // Temporarily keeping this function for backwards compatibility
    static func setUserID(_ userID: String) -> Bool {
        return NeuroID.shared.identify(userID)
    }

    static func getSessionID() -> String {
        return NeuroID.shared.getSessionID()
    }

    static func setRegisteredUserID(_ registeredUserID: String) -> Bool {
        return NeuroID.shared.setRegisteredUserID(registeredUserID)
    }

    static func getRegisteredUserID() -> String {
        return NeuroID.shared.getRegisteredUserID()
    }
}
