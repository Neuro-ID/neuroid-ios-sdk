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
        if NeuroID.clientID != nil {
            cid = NeuroID.clientID
        }
        // Ensure we aren't on old client id
        if cid != nil && !cid!.contains("_") {
            return cid!
        } else {
            cid = ParamsCreator.generateID()
            NeuroID.clientID = cid
            setUserDefaultKey(clientIdName, value: cid)
            return cid!
        }
    }

    @available(*, deprecated, message: "setSiteId is deprecated and no longer required")
    static func setSiteId(siteId: String) {
        NIDLog.i("**** NOTE: THIS METHOD IS DEPRECATED")
        self.siteID = siteId
    }
}

// Internal Only Functions
extension NeuroID {
    static func getClientKeyFromLocalStorage() -> String {
        let key = getUserDefaultKeyString(Constants.storageClientKey.rawValue)
        return key ?? ""
    }

    static func getClientKey() -> String {
        guard let key = NeuroID.clientKey else {
            NIDLog.e("ClientKey is not set")
            return ""
        }
        return key
    }

    /**
     Takes an optional string, if the string is nil or matches the cached config siteID then it
       is the "collection" site meaning the siteID that belongs to the clientKey given
       in the `configure` command
     */
    static func isCollectionSite(siteID: String?) -> Bool {
        return siteID == nil || siteID ?? "" == NeuroID.configService.configCache.siteID ?? "noID"
    }

    static func addLinkedSiteID(_ siteID: String) {
        if !NeuroID.validationService.validateSiteID(siteID) {
            return
        }

        NeuroID.linkedSiteID = siteID

        // Add the SET_LINKED_SITE event for MIHR purposes
        //  this event is ignore by the collector service
        let setLinkedSiteIDEvent = NIDEvent(sessionEvent: NIDSessionEventName.setLinkedSite)
        setLinkedSiteIDEvent.v = siteID
        saveEventToLocalDataStore(setLinkedSiteIDEvent)
    }
}
