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
}
