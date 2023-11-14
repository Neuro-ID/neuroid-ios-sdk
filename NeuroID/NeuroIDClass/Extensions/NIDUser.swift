//
//  NIDUser.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation

public extension NeuroID {
    static func setUserID(_ userId: String) -> Bool {
        // user ids must be from 3 to 100 ascii alhpa numeric characters and can include `.`, `-`, and `_`
        do {
            let expression = try NSRegularExpression(pattern: "^[a-zA-Z0-9-_.]{3,100}$", options: NSRegularExpression.Options(rawValue: 0))
            let result = expression.matches(in: userId, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, userId.count))
            if result.count != 1 {
                NIDLog.e(NIDError.invalidUserID.rawValue)
                return false
            }
        } catch {
            NIDLog.e(NIDError.invalidUserID.rawValue)
            return false
        }

        NIDLog.d(tag: "\(Constants.userTag.rawValue)", "\(userId)")

        NeuroID.userId = userId

        let setUserEvent = NIDEvent(sessionEvent: NIDSessionEventName.setUserId)
        setUserEvent.uid = userId

        if !NeuroID.isSDKStarted {
            saveQueuedEventToLocalDataStore(setUserEvent)
        } else {
            saveEventToLocalDataStore(setUserEvent)
        }

        return true
    }

    static func getUserID() -> String {
        return NeuroID.userId ?? ""
    }
}
