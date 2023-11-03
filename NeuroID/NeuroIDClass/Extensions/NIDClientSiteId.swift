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
        let clientIdName = Constants.storageClientIdKey.rawValue
        var cid = getUserDefaultKeyString(clientIdName)
        if NeuroID.clientId != nil {
            cid = NeuroID.clientId
        }
        // Ensure we aren't on old client id
        if cid != nil && !cid!.contains("_") {
            return cid!
        } else {
            cid = ParamsCreator.genId()
            NeuroID.clientId = cid
            setUserDefaultKey(clientIdName, value: cid)
            return cid!
        }
    }

    internal static func getClientKeyFromLocalStorage() -> String {
        let key = getUserDefaultKeyString(Constants.storageClientKey.rawValue)
        return key ?? ""
    }

    internal static func getClientKey() -> String {
        guard let key = NeuroID.clientKey else {
            NIDLog.e("ClientKey is not set")
            return ""
        }
        return key
    }

    static func setSiteId(siteId: String) {
        NIDPrintLog("**** NeuroID NOTE: THIS METHOD IS DEPRECATED")
        self.siteId = siteId
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
}
