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

        // user ids must be from 3 to 100 ascii alhpa numeric characters and can include `.`, `-`, and `_`
        let expression = try NSRegularExpression(pattern: "^[a-zA-Z0-9-_.]{3,100}$", options: NSRegularExpression.Options(rawValue: 0))
        let result = expression.matches(in: userId, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, userId.count))
        if result.count != 1 {
            throw NIDError.invalidUserID
        }

        setUserDefaultKey(Constants.storageUserIdKey.rawValue, value: userId)
        NeuroID.userId = userId

        NIDDebugPrint(tag: "\(Constants.userTag.rawValue)", "NID userID = <\(userId)>")

        let setUserEvent = NIDEvent(sessionEvent: NIDSessionEventName.setUserId)
        setUserEvent.uid = userId
        saveEventToLocalDataStore(setUserEvent)
    }

    static func getUserID() -> String {
        let userId = getUserDefaultKeyString(Constants.storageUserIdKey.rawValue)
        return NeuroID.userId ?? userId ?? ""
    }
}
