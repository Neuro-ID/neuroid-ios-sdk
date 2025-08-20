//
//  NIDUser.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation

public extension NeuroID {
    // This command replaces `setUserID`
    // Formerly known as userID, now within the mobile sdk ONLY sessionID
    func identify(_ sessionID: String) -> Bool {
        return self.identifierService.setSessionID(sessionID, true)
    }

    // This command replaces `getUserID`
    // Formerly known as userID, now within the mobile sdk ONLY sessionID
    func getSessionID() -> String {
        return self.identifierService.sessionID ?? ""
    }

    func getRegisteredUserID() -> String {
        return self.registeredUserID
    }

    func setRegisteredUserID(_ registeredUserID: String) -> Bool {
        return self.identifierService.setRegisteredUserID(registeredUserID)
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
            NeuroID.shared.saveEventToDataStore(NIDEvent(type: .attemptedLogin, uid: "scrubbed-id-failed-validation"))
        }
        return true
    }
}
