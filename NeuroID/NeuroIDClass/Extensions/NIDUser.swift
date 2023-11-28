//
//  NIDUser.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation

public extension NeuroID {
    internal static func validateUserID(_ userId: String) -> Bool {
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

        return true
    }

    internal static func setGenericUserID(userId: String, type: UserIDTypes, completion: (Bool) -> Bool) -> Bool {
        let validID = NeuroID.validateUserID(userId)
        if !validID { return completion(validID) }

        NIDLog.d(tag: "\(type)", "\(userId)")

        let setUserEvent = NIDEvent(
            sessionEvent: type == .userID ?
                NIDSessionEventName.setUserId : NIDSessionEventName.setRegisteredUserId
        )

        setUserEvent.uid = userId

        if !NeuroID.isSDKStarted {
            saveQueuedEventToLocalDataStore(setUserEvent)
        } else {
            saveEventToLocalDataStore(setUserEvent)
        }

        return completion(true)
    }

    static func setUserID(_ userId: String) -> Bool {
        let res = setGenericUserID(
            userId: userId, type: .userID
        ) { success in
            if success {
                NeuroID.userId = userId
            }
            return success
        }

        return res
    }

    static func getUserID() -> String {
        return NeuroID.userId ?? ""
    }

    static func getRegisteredUserID() -> String {
        return NeuroID.registeredUserId
    }

    static func setRegisteredUserID(_ registeredUserID: String) -> Bool {
        let res = setGenericUserID(
            userId: registeredUserID, type: .registeredUserID
        ) { success in
            if success {
                NeuroID.registeredUserId = registeredUserID
            }
            return success
        }

        return res
    }
}
