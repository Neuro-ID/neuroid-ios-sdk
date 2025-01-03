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
    
    internal static func validateIdentifier(_ identitier: String) -> Bool {
        // user ids must be from 3 to 100 ascii alhpa numeric characters and can include `.`, `-`, and `_`
        do {
            let expression = try NSRegularExpression(pattern: "^[a-zA-Z0-9-_.]{3,100}$", options: NSRegularExpression.Options(rawValue: 0))
            let result = expression.matches(in: identitier, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, identitier.count))
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
    
    internal static func setGenericIdentifier(type: UserIDTypes, genericIdentifier: String, userGenerated: Bool = true) -> Bool {
        let validID = validateIdentifier(genericIdentifier)
        
        sendOriginEvent(
            getOriginResult(
                idValue: genericIdentifier,
                validID: validID,
                userGenerated: userGenerated,
                idType: type
            )
        )
            
        if !validID {
            saveEventToDataStore(
                NIDEvent(
                    type: NIDEventName.log,
                    level: "ERROR",
                    m: "Failed to save genericIdentifier of \(type.rawValue) event:\(scrubIdentifier(genericIdentifier))"
                )
            )
            return false
        }
            
        NIDLog.d(tag: "\(type)", "\(genericIdentifier)")
        //    Queue user id event to be sent
        var setIdentifierEvent: NIDEvent
        if type == .attemptedLogin {
            setIdentifierEvent = NIDEvent(uid: genericIdentifier)
        } else {
            setIdentifierEvent = NIDEvent(
                sessionEvent: type == .userID ?
                    NIDSessionEventName.setUserId : NIDSessionEventName.setRegisteredUserId
            )
            setIdentifierEvent.uid = genericIdentifier
        }
        
        saveEventToDataStore(setIdentifierEvent)
        
        return true
    }
    
    internal static func sendOriginEvent(_ originResult: SessionIDOriginalResult) {
        saveEventToDataStore(
            NIDEvent(
                sessionEvent: NIDSessionEventName.setVariable,
                key: "sessionIdCode",
                v: originResult.originCode
            )
        )
        saveEventToDataStore(
            NIDEvent(
                sessionEvent: NIDSessionEventName.setVariable,
                key: "sessionIdSource",
                v: originResult.origin
            )
        )
        saveEventToDataStore(
            NIDEvent(
                sessionEvent: NIDSessionEventName.setVariable,
                key: "sessionId",
                v: "\(originResult.idValue)"
            )
        )
        saveEventToDataStore(
            NIDEvent(
                sessionEvent: NIDSessionEventName.setVariable,
                key: "sessionIdType",
                v: originResult.idType.rawValue
            )
        )
    }
    
    internal static func getOriginResult(
        idValue: String,
        validID: Bool,
        userGenerated: Bool,
        idType: UserIDTypes
    ) -> SessionIDOriginalResult {
        let origin = userGenerated ? SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue : SessionOrigin.NID_ORIGIN_NID_SET.rawValue
        var originCode = SessionOrigin.NID_ORIGIN_CODE_FAIL.rawValue
        if validID {
            originCode = userGenerated ? SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue : SessionOrigin.NID_ORIGIN_CODE_NID.rawValue
        }
        return SessionIDOriginalResult(origin: origin, originCode: originCode, idValue: idValue, idType: idType)
    }
    
    // This command replaces `setUserID`
    // Formerly known as userID, now within the mobile sdk ONLY sessionID
    static func identify(_ sessionID: String) -> Bool {
        return setSessionID(sessionID, true)
    }
    
    // This command replaces `setUserID` (internal version)
    // Formerly known as userID, now within the mobile sdk ONLY sessionID
    internal static func setSessionID(_ sessionID: String, _ userGenerated: Bool) -> Bool {
        saveEventToDataStore(
            NIDEvent(
                type: NIDEventName.log,
                level: "INFO",
                m: "Set UserID/SessionID Attempt: \(scrubIdentifier(sessionID))"
            )
        )
        
        let validID = setGenericIdentifier(type: .userID, genericIdentifier: sessionID, userGenerated: userGenerated)
        
        if !validID {
            return false
        }
        
        NeuroID.sessionID = sessionID
        return true
    }
    
    static func getRegisteredUserID() -> String {
        return NeuroID.registeredUserID
    }
    
    static func setRegisteredUserID(_ registeredUserID: String) -> Bool {
        saveEventToDataStore(
            NIDEvent(
                type: NIDEventName.log,
                level: "INFO",
                m: "Set Registered UserID Attempt: \(scrubIdentifier(registeredUserID))"
            )
        )
        
        if !NeuroID.registeredUserID.isEmpty, registeredUserID != NeuroID.registeredUserID {
            NeuroID.saveEventToLocalDataStore(
                NIDEvent(
                    level: "WARN",
                    m: "Multiple Registered UserID Attempt - existing:\(NeuroID.registeredUserID) new:\(scrubIdentifier(registeredUserID))"
                )
            )
        
            NIDLog.e("Multiple Registered UserID Attempt: Only 1 Registered UserID can be set per session")
        }
        
        let validID = setGenericIdentifier(type: .registeredUserID, genericIdentifier: registeredUserID)
        
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
        saveEventToDataStore(
            NIDEvent(
                type: NIDEventName.log,
                level: "INFO",
                m: "Attempted login with attemptedRegisteredUserId: \(scrubIdentifier(attemptedRegisteredUserId ?? "null"))"
            )
        )

        let captured = setGenericIdentifier(
            type: .attemptedLogin,
            genericIdentifier: attemptedRegisteredUserId ?? "scrubbed-id-failed-validation",
            userGenerated: attemptedRegisteredUserId != nil
        )
        
        if !captured {
            saveEventToDataStore(NIDEvent(uid: "scrubbed-id-failed-validation"))
        }
        return true
    }
    
    internal static func scrubIdentifier(_ identifier: String) -> String {
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
