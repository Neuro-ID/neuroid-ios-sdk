//
//  NIDClientSiteId.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation

// Internal Only Functions
extension NeuroIDCore {
    /**
     Public user facing getClientID function via Static Instance
     */
    func getClientID() -> String {
        if self.clientID != nil, !self.clientID!.contains("_") {
            return self.clientID!
        }

        let storedClientID = getUserDefaultKeyString(Constants.storageClientIDKey.rawValue)
        if let tempClientID = storedClientID, !tempClientID.contains("_") {
            // NOTE: This returns the clientID that is stored, but the self.clientID attribute will still be nil
            return tempClientID
        }

        let newClientID = ParamsCreator.generateID()
        self.clientID = newClientID
        setUserDefaultKey(Constants.storageClientIDKey.rawValue, value: newClientID)

        return newClientID
    }

    func getClientKeyFromLocalStorage() -> String {
        let key = getUserDefaultKeyString(Constants.storageClientKey.rawValue)
        return key ?? ""
    }

    func getClientKey() -> String {
        guard let key = self.clientKey else {
            NIDLog.error("ClientKey is not set")
            return ""
        }
        return key
    }

    func addLinkedSiteID(_ siteID: String) {
        if !self.validationService.validateSiteID(siteID) {
            return
        }

        self.linkedSiteID = siteID

        self.eventStorageService.saveEventToLocalDataStore(
            NIDEvent(type: .setLinkedSite, v: siteID)
        )
    }
}
