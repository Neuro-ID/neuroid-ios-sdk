//
//  StateStore.swift
//  NeuroID
//

class StateStore {
    private(set) var identityId: String?  // Formerly known as userID, now within the mobile sdk ONLY identityId
    
    func setIdentityId(_ identityId: String?) {
        self.identityId = identityId
    }
}
