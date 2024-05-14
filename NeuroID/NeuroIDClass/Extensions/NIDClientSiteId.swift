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

    static func validateClientKey(_ clientKey: String) -> Bool {
        var validKey = false

        let pattern = "key_(live|test)_[A-Za-z0-9]+"
        let regex = try! NSRegularExpression(pattern: pattern)

        if let _ = regex.firstMatch(
            in: clientKey,
            options: NSRegularExpression.MatchingOptions(rawValue: 0),
            range: NSMakeRange(0, clientKey.count)
        ) {
            validKey = true
        }

        return validKey
    }

    static func validateSiteID(_ string: String) -> Bool {
        let regex = #"^form_[a-zA-Z0-9]{5}\d{3}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)

        let valid = predicate.evaluate(with: string)

        if !valid {
            NIDLog.e("Invalid SiteID/AppID")
        }

        return valid
    }

    static func addLinkedSiteID(_ siteID: String) {
        if !NeuroID.validateSiteID(siteID) {
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
