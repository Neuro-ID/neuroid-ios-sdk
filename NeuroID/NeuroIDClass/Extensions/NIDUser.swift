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
                // If Validation fails send origin event
                if CURRENT_ORIGIN == nil {
                    CURRENT_ORIGIN = SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue
                }
                CURRENT_ORIGIN_CODE = SessionOrigin.NID_ORIGIN_CODE_FAIL.rawValue

                sendOriginEvent(origin: CURRENT_ORIGIN!, originCode: CURRENT_ORIGIN_CODE!, originSessionID: userId)

                return false
            }
        } catch {
            NIDLog.e(NIDError.invalidUserID.rawValue)
            // Redundant check to ensure CURRENT_ORIGIN is never unsafely accessed
            if CURRENT_ORIGIN == nil {
                CURRENT_ORIGIN = SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue
            }
            CURRENT_ORIGIN_CODE = SessionOrigin.NID_ORIGIN_CODE_FAIL.rawValue

            sendOriginEvent(origin: CURRENT_ORIGIN!, originCode: CURRENT_ORIGIN_CODE!, originSessionID: userId)
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

    internal static func sendOriginEvent(origin: String, originCode: String, originSessionID: String) {
        let sessionIdCodeEvent =
            NIDEvent(
                sessionEvent: NIDSessionEventName.setVariable,
                key: "sessionIdCode",
                v: originCode
            )

        let sessionIdSourceEvent =
            NIDEvent(
                sessionEvent: NIDSessionEventName.setVariable,
                key: "sessionIdSource",
                v: origin
            )

        let sessionIdEvent =
            NIDEvent(
                sessionEvent: NIDSessionEventName.setVariable,
                key: "sessionId",
                v: originSessionID
            )

        if !NeuroID.isSDKStarted {
            saveQueuedEventToLocalDataStore(sessionIdCodeEvent)
            saveQueuedEventToLocalDataStore(sessionIdSourceEvent)
            saveQueuedEventToLocalDataStore(sessionIdEvent)
        } else {
            saveEventToLocalDataStore(sessionIdCodeEvent)
            saveEventToLocalDataStore(sessionIdSourceEvent)
            saveEventToLocalDataStore(sessionIdEvent)
        }
    }

    static func setUserID(_ userId: String) -> Bool {
        // Redundant check to ensure CURRENT_ORIGIN is never unsafely accessed
        if CURRENT_ORIGIN == nil {
            CURRENT_ORIGIN = SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue
            CURRENT_ORIGIN_CODE = SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue
        }
        let res = setGenericUserID(
            userId: userId, type: .userID
        ) { success in
            if success {
                sendOriginEvent(origin: CURRENT_ORIGIN!, originCode: CURRENT_ORIGIN_CODE!, originSessionID: userId)
                NeuroID.userID = userId
            }

            return success
        }

        return res
    }

    static func getUserID() -> String {
        return NeuroID.userID ?? ""
    }

    static func getRegisteredUserID() -> String {
        return NeuroID.registeredUserID
    }

    static func setRegisteredUserID(_ registeredUserID: String) -> Bool {
        let res = setGenericUserID(
            userId: registeredUserID, type: .registeredUserID
        ) { success in
            if success {
                NeuroID.registeredUserID = registeredUserID
            }
            CURRENT_ORIGIN = SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue
            CURRENT_ORIGIN_CODE = SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue
            sendOriginEvent(origin: CURRENT_ORIGIN!, originCode: CURRENT_ORIGIN_CODE!, originSessionID: registeredUserID)

            return success
        }

        return res
    }

    /**
        This should be called the moment a user trys to login. Returns true always
        @param {String} [attemptedRegisteredUserId] - an optional identifier for the login
     */
    static func attemptedLogin(_ attemptedRegisteredUserId: String? = nil) -> Bool {
        if NeuroID.validateUserID(attemptedRegisteredUserId ?? "") {
            NeuroID.saveEventToLocalDataStore(NIDEvent(uid: attemptedRegisteredUserId))
        } else {
            NeuroID.saveEventToLocalDataStore(NIDEvent(uid: "scrubbed-id-failed-validation"))
        }
        return true
    }
}
