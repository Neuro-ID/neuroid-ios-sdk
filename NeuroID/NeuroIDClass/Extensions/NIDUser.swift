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
            
        if !validID {
            let saveIdFailureEvent = NIDEvent(type: NIDEventName.log, level: "ERROR", m: "Failed to save genericUserID event:\(scrubIdentifier(identifier: genericUserID))")
            saveEventToDataStore(saveIdFailureEvent)
            return false
        }
            
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
//        Save log event
        let setUserIdLogEvent = NIDEvent(type: NIDEventName.log, level: "INFO", m: "Set User Id Attempt: \(scrubIdentifier(identifier: userId))")
        saveEventToDataStore(setUserIdLogEvent)
        
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
//        Save log event
        let setRegisteredUserIdLogEvent = NIDEvent(type: NIDEventName.log, level: "INFO", m: "Set Registered User Id Attempt: \(scrubIdentifier(identifier: registeredUserID))")
        saveEventToDataStore(setRegisteredUserIdLogEvent)
       
        if !NeuroID.registeredUserID.isEmpty, registeredUserID != NeuroID.registeredUserID {
            NeuroID.saveEventToLocalDataStore(NIDEvent(level: "warn", m: "Multiple Registered User Id Attempts : \(scrubIdentifier(identifier: registeredUserID))"))
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
//        Save log event
        let attemptedLoginAttemptLogEvent = NIDEvent(type: NIDEventName.log, level: "INFO", m: "attempted login with attemptedRegisteredUserId: \(scrubIdentifier(identifier: attemptedRegisteredUserId ?? "null"))")
        saveEventToDataStore(attemptedLoginAttemptLogEvent)

        let captured = setGenericUserID(type: .attemptedLogin, genericUserID: attemptedRegisteredUserId ?? "scrubbed-id-failed-validation", userGenerated: attemptedRegisteredUserId != nil)
        
        if !captured {
            saveEventToDataStore(NIDEvent(uid: "scrubbed-id-failed-validation"))
        }
        return true
    }
    
    internal static func scrubIdentifier(identifier: String) -> String {
        do {
            let emailRegex = try NSRegularExpression(pattern: "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}")
            let ssnRegex = try NSRegularExpression(pattern: "\\b\\d{3}-\\d{2}-\\d{4}\\b")
            var result = emailRegex.matches(in: identifier, range: NSMakeRange(0, identifier.count))
            if !result.isEmpty {
                let atIndex = identifier.firstIndex(of: "@") ?? identifier.endIndex
                let idLength = identifier.distance(from: identifier.startIndex, to: atIndex)
                let scrubbedEmailId = String(identifier.prefix(1)) + String(repeating: "*", count: idLength - 1) + identifier[atIndex...]
                return scrubbedEmailId
            }
            result = ssnRegex.matches(in: identifier, range: NSMakeRange(0, identifier.count))
            if !result.isEmpty {
                return "***-**-****"
            }
            return identifier
        } catch let error as NSError {
            NIDLog.e("Invalid pattern: \(error.localizedDescription)")
            return identifier
        }
    }
}
