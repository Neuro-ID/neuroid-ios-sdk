//
//  NIDUser.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation

public extension NeuroID {
    static func setUserID(_ userId: String) throws {
        if !NeuroID.isSDKStarted {
            throw NIDError.sdkNotStarted
        }

        UserDefaults.standard.set(userId, forKey: Constants.storageUserIdKey.rawValue)
        let setUserEvent = NIDEvent(session: NIDSessionEventName.setUserId, userId: userId)
        NeuroID.userId = userId
        NIDDebugPrint(tag: "\(Constants.userTag.rawValue)", "NID userID = <\(userId)>")
        saveEventToLocalDataStore(setUserEvent)
    }

    static func getUserID() -> String {
        let userId = UserDefaults.standard.string(forKey: Constants.storageUserIdKey.rawValue)
        return NeuroID.userId ?? userId ?? ""
    }
}
