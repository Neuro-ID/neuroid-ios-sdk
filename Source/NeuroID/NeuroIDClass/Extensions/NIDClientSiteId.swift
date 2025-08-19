//
//  NIDClientSiteId.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation

public extension NeuroID {
    /**
     Public user facing getClientID function
     */
    static func getClientID() -> String {
        let clientIdName = Constants.storageClientIDKey.rawValue
        var cid = getUserDefaultKeyString(clientIdName)
        if NeuroID.shared.clientID != nil {
            cid = NeuroID.shared.clientID
        }
        // Ensure we aren't on old client id
        if cid != nil && !cid!.contains("_") {
            return cid!
        } else {
            cid = ParamsCreator.generateID()
            NeuroID.shared.clientID = cid
            setUserDefaultKey(clientIdName, value: cid)
            return cid!
        }
    }

    @available(*, deprecated, message: "setSiteId is deprecated and no longer required")
    static func setSiteId(siteId: String) {
        NeuroID.shared.logger.i("**** NOTE: THIS METHOD IS DEPRECATED")
        self.shared.siteID = siteId
    }
}

// Internal Only Functions
extension NeuroID {
    func getClientKeyFromLocalStorage() -> String {
        let key = getUserDefaultKeyString(Constants.storageClientKey.rawValue)
        return key ?? ""
    }

    func getClientKey() -> String {
        guard let key = self.clientKey else {
            self.logger.e("ClientKey is not set")
            return ""
        }
        return key
    }

    /**
     Takes an optional string, if the string is nil or matches the cached config siteID then it
       is the "collection" site meaning the siteID that belongs to the clientKey given
       in the `configure` command
     */
    func isCollectionSite(siteID: String?) -> Bool {
        return siteID == nil || siteID ?? "" == self.configService.configCache.siteID ?? "noID"
    }

    static func addLinkedSiteID(_ siteID: String) {
        if !NeuroID.shared.validationService.validateSiteID(siteID) {
            return
        }

        NeuroID.shared.linkedSiteID = siteID

        saveEventToLocalDataStore(
            NIDEvent(type: .setLinkedSite, v: siteID)
        )
    }
}
