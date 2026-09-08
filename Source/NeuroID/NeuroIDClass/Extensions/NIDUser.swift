//
//  NIDUser.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation

extension NeuroIDCore {

    func getIdentityId() -> String {
        return state.identityId ?? ""
    }

    func identify(_ identityId: String) -> Bool {
        return self.identifierService.setIdentityId(identityId, true)
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
            self.eventService.saveEventToDataStore(
                NIDEvent(type: .attemptedLogin, uid: "scrubbed-id-failed-validation")
            )
        }
        return true
    }
}
