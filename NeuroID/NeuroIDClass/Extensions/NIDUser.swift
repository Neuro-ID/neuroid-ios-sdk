//
//  NIDUser.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation

public extension NeuroID {
    struct SessionIDOriginalResult {
        let origin: String
        let originCode: String
        let idValue: String
        let idType: UserIDTypes
    }
    
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
    
    internal static func setGenericUserID(type: UserIDTypes, genericUserID: String, userGenerated: Bool = true) -> Bool {
        let validID = validateUserID(genericUserID)
        
        let originRes = getOriginResult(idValue: genericUserID, validID: validID, userGenerated: userGenerated, idType: type)
        sendOriginEvent(originResult: originRes)
        
        if !validID { return false }
        
        NIDLog.d(tag: "\(type)", "\(genericUserID)")
        //    Queue user id event to be sent
        var setUserEvent: NIDEvent
        if type == .attemptedLogin {
            setUserEvent = NIDEvent(uid: genericUserID)
        } else {
            setUserEvent = NIDEvent(
                sessionEvent: type == .userID ?
                    NIDSessionEventName.setUserId : NIDSessionEventName.setRegisteredUserId
            )
            setUserEvent.uid = genericUserID
        }
        
        saveEventToDataStore(setUserEvent)
        
        return true
    }
    
    internal static func sendOriginEvent(originResult: SessionIDOriginalResult) {
        let sessionIdCodeEvent =
            NIDEvent(
                sessionEvent: NIDSessionEventName.setVariable,
                key: "sessionIdCode",
                v: originResult.originCode
            )
        
        let sessionIdSourceEvent =
            NIDEvent(
                sessionEvent: NIDSessionEventName.setVariable,
                key: "sessionIdSource",
                v: originResult.origin
            )
        
        let sessionIdEvent =
            NIDEvent(
                sessionEvent: NIDSessionEventName.setVariable,
                key: "sessionId",
                v: "\(originResult.idValue)"
            )
        
        let sessionIdTypeEvent =
            NIDEvent(
                sessionEvent: NIDSessionEventName.setVariable,
                key: "sessionIdType",
                v: originResult.idType.rawValue
            )
        
        saveEventToDataStore(sessionIdCodeEvent)
        saveEventToDataStore(sessionIdSourceEvent)
        saveEventToDataStore(sessionIdEvent)
        saveEventToDataStore(sessionIdTypeEvent)
    }
    
    internal static func getOriginResult(idValue: String,
                                         validID: Bool,
                                         userGenerated: Bool,
                                         idType: UserIDTypes) -> SessionIDOriginalResult
    {
        let origin = userGenerated ? SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue : SessionOrigin.NID_ORIGIN_NID_SET.rawValue
        var originCode = SessionOrigin.NID_ORIGIN_CODE_FAIL.rawValue
        if validID {
            originCode = userGenerated ? SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue : SessionOrigin.NID_ORIGIN_CODE_NID.rawValue
        }
        return SessionIDOriginalResult(origin: origin, originCode: originCode, idValue: idValue, idType: idType)
    }
    
    static func setUserID(_ userId: String) -> Bool {
        return setUserID(userId, true)
    }
    
    internal static func setUserID(_ userId: String, _ userGenerated: Bool) -> Bool {
        let validID = setGenericUserID(type: .userID, genericUserID: userId, userGenerated: userGenerated)
        
        if !validID {
            return false
        }
        
        NeuroID.userID = userId
        return true
    }
    
    static func getUserID() -> String {
        return NeuroID.userID ?? ""
    }
    
    static func getRegisteredUserID() -> String {
        return NeuroID.registeredUserID
    }
    
    static func setRegisteredUserID(_ registeredUserID: String) -> Bool {
        if !NeuroID.registeredUserID.isEmpty, registeredUserID != NeuroID.registeredUserID {
            NeuroID.saveEventToLocalDataStore(NIDEvent(level: "warn", m: "Multiple Registered User Id Attempts"))
            NIDLog.e("Multiple Registered UserID Attempt: Only 1 Registered UserID can be set per session")
            return false
        }
        
        let validID = setGenericUserID(type: .registeredUserID, genericUserID: registeredUserID)
        
        if !validID {
            return false
        }
        
        NeuroID.registeredUserID = registeredUserID
        return true
    }
    
    /**
     This should be called the moment a user trys to login. Returns true always
     @param {String} [attemptedRegisteredUserId] - an optional identifier for the login
     */
    static func attemptedLogin(_ attemptedRegisteredUserId: String? = nil) -> Bool {
        let captured = setGenericUserID(type: .attemptedLogin, genericUserID: attemptedRegisteredUserId ?? "scrubbed-id-failed-validation", userGenerated: attemptedRegisteredUserId != nil)
        
        if !captured {
            if !NeuroID.isSDKStarted {
                saveQueuedEventToLocalDataStore(NIDEvent(uid: "scrubbed-id-failed-validation"))
            } else {
                saveEventToLocalDataStore(NIDEvent(uid: "scrubbed-id-failed-validation"))
            }
        }
        return true
    }
}
