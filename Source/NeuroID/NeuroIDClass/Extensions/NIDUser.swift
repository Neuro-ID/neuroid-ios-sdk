//
//  NIDUser.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation

extension NeuroIDCore {
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

    func setRegisteredUserID(_ registeredUserID: String) -> Bool {
        return self.identifierService.setRegisteredUserID(registeredUserID)
    }

    func getRegisteredUserID() -> String {
        return self.identifierService.registeredUserID
    }

    func attemptedLogin(_ attemptedRegisteredUserId: String? = nil) -> Bool {
        let validID = self.identifierService.setGenericIdentifier(
            identifier: attemptedRegisteredUserId ?? "scrubbed-id-failed-validation",
            type: .attemptedLogin,
            userGenerated: attemptedRegisteredUserId != nil,
            duplicatesAllowedCheck: { _ in true },
            validIDFunction: {}
        )

        if !validID {
            self.eventStorageService.saveEventToDataStore(
                NIDEvent(type: .attemptedLogin, uid: "scrubbed-id-failed-validation")
            )
        }
        return true
    }
}
