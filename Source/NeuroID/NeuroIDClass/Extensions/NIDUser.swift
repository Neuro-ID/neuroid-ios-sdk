//
//  NIDUser.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation

public extension NeuroID {
    // Temporarily keeping this function for backwards compatibility
    static func setUserID(_ userID: String) -> Bool {
        return identify(userID)
    }

    // Temporarily keeping this function for backwards compatibility
    static func getUserID() -> String {
        return NeuroID.getSessionID()
    }

    // This command replaces `setUserID`
    // Formerly known as userID, now within the mobile sdk ONLY sessionID
    static func identify(_ sessionID: String) -> Bool {
        return NeuroID.shared.identifierService.setSessionID(sessionID, true)
    }

    // This command replaces `getUserID`
    // Formerly known as userID, now within the mobile sdk ONLY sessionID
    static func getSessionID() -> String {
        return NeuroID.shared.identifierService.sessionID ?? ""
    }

    static func getRegisteredUserID() -> String {
        return NeuroID.registeredUserID
    }

    static func setRegisteredUserID(_ registeredUserID: String) -> Bool {
        return NeuroID.shared.identifierService.setRegisteredUserID(registeredUserID)
    }

    /**
     This should be called the moment a user trys to login. Returns true always
     @param {String} [attemptedRegisteredUserId] - an optional identifier for the login
     */
    static func attemptedLogin(_ attemptedRegisteredUserId: String? = nil) -> Bool {
        let validID = NeuroID.shared.identifierService.setGenericIdentifier(
            identifier: attemptedRegisteredUserId ?? "scrubbed-id-failed-validation",
            type: .attemptedLogin,
            userGenerated: attemptedRegisteredUserId != nil,
            duplicatesAllowedCheck: { _ in true },
            validIDFunction: {}
        )

        if !validID {
            saveEventToDataStore(NIDEvent(type: .attemptedLogin, uid: "scrubbed-id-failed-validation"))
        }
        return true
    }
}
