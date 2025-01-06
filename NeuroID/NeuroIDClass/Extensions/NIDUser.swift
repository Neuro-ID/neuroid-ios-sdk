//
//  NIDUser.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation

extension NeuroID {
    // This command replaces `getUserID`
    // Formerly known as userID, now within the mobile sdk ONLY sessionID
    public static func getSessionID() -> String {
        return NeuroID.sessionID ?? ""
    }
    
    // This command replaces `setUserID`
    // Formerly known as userID, now within the mobile sdk ONLY sessionID
    public static func identify(_ sessionID: String) -> Bool {
        return NeuroID.identifierService.setSessionID(sessionID, true)
    }

    public static func getRegisteredUserID() -> String {
        return NeuroID.registeredUserID
    }

    public static func setRegisteredUserID(_ registeredUserID: String) -> Bool {
        return NeuroID.identifierService.setRegisteredUserID(registeredUserID)
    }

    /**
     This should be called the moment a user trys to login. Returns true always
     @param {String} [attemptedRegisteredUserId] - an optional identifier for the login
     */
    public static func attemptedLogin(
        _ attemptedRegisteredUserId: String? = nil
    ) -> Bool {

        let validID = NeuroID.identifierService.setGenericIdentifier(
                identifier: attemptedRegisteredUserId ?? "scrubbed-id-failed-validation",
                type: .attemptedLogin,
                userGenerated: attemptedRegisteredUserId != nil,
                duplicatesAllowedCheck: { _ in return true },
                validIDFunction: {}
            )

        if !validID {
            saveEventToDataStore(NIDEvent(uid: "scrubbed-id-failed-validation"))
        }
        return true
    }

}
