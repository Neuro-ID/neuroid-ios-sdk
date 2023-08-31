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
        var cid = UserDefaults.standard.string(forKey: clientIdName)
        if NeuroID.clientId != nil {
            cid = NeuroID.clientId
        }
        // Ensure we aren't on old client id
        if cid != nil && !cid!.contains("_") {
            return cid!
        } else {
            cid = ParamsCreator.genId()
            NeuroID.clientId = cid
            UserDefaults.standard.set(cid, forKey: clientIdName)
            return cid!
        }
    }

    internal static func getClientKeyFromLocalStorage() -> String {
        let key = UserDefaults.standard.string(forKey: Constants.storageClientKey.rawValue)
        return key ?? ""
    }

    internal static func getClientKey() -> String {
        guard let key = NeuroID.clientKey else {
            print("Error: clientKey is not set")
            return ""
        }
        return key
    }

    static func setSiteId(siteId: String) {
        self.siteId = siteId
    }
}
