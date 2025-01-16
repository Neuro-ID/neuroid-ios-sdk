//
//  IdentifierService.swift
//  NeuroID
//
//  Created by Kevin Sites on 1/14/25.
//

import Foundation

protocol IdentifierServiceProtocol {
    func setSessionID(_ sessionID: String, _ userGenerated: Bool) -> Bool

    func setRegisteredUserID(_ registeredUserID: String) -> Bool

    func setGenericIdentifier(
        identifier: String,
        type: UserIDTypes,
        userGenerated: Bool,
        duplicatesAllowedCheck: (_ scrubbedIdentifier: String) -> Bool,
        validIDFunction: () -> Void
    ) -> Bool

    func logScrubbedIdentityAttempt(
        identifier: String, message: String
    ) -> String

    func scrubIdentifier(_ identifier: String) -> String
}

struct SessionIDOriginalResult {
    let origin: String
    let originCode: String
    let idValue: String
    let idType: UserIDTypes
}

class IdentifierService: IdentifierServiceProtocol {
    let neuroID: NeuroID.Type
    let logger: NIDLog.Type

    init(
        of neuroID: NeuroID.Type,
        of logger: NIDLog.Type
    ) {
        self.neuroID = neuroID
        self.logger = logger
    }

    // This command replaces `setUserID` (internal version)
    func setSessionID(_ sessionID: String, _ userGenerated: Bool) -> Bool {
        let validID = setGenericIdentifier(
            identifier: sessionID,
            type: .sessionID,
            userGenerated: userGenerated,
            duplicatesAllowedCheck: { _ in return true }
        ) {
            neuroID.sessionID = sessionID
        }

        return validID
    }

    func setRegisteredUserID(_ registeredUserID: String) -> Bool {
        let validID = setGenericIdentifier(
            identifier: registeredUserID,
            type: .registeredUserID,
            duplicatesAllowedCheck: { scrubbedIdentifier in
                if !neuroID.registeredUserID.isEmpty,
                    registeredUserID != neuroID.registeredUserID
                {
                    neuroID.saveEventToLocalDataStore(
                        NIDEvent(
                            type: .log,
                            level: "WARN",
                            m:
                                "Multiple Registered UserID Attempt - existing:\(neuroID.registeredUserID) new:\(scrubbedIdentifier)"
                        )
                    )

                    logger.e(
                        "Multiple Registered UserID Attempt: Only 1 Registered UserID can be set per session"
                    )
                }
                return true
            }
        ) {
            neuroID.registeredUserID = registeredUserID
        }

        return validID

    }

    func setGenericIdentifier(
        identifier: String,
        type: UserIDTypes,
        userGenerated: Bool = true,
        duplicatesAllowedCheck: (_ scrubbedIdentifier: String) -> Bool = { _ in
            return true
        },
        validIDFunction: () -> Void = {}
    ) -> Bool {
        let scrubbedIdentifier = logScrubbedIdentityAttempt(
            identifier: identifier, message: "\(type.rawValue) Attempt"
        )

        // Allow custom logic to happen pre-validation and setting of ID
        let duplicatesAllowed = duplicatesAllowedCheck(scrubbedIdentifier)
        if !duplicatesAllowed {
            return false
        }

        let validID = validateIdentifier(identifier)

        sendOriginEvent(
            getOriginResult(
                idValue: identifier,
                validID: validID,
                userGenerated: userGenerated,
                idType: type
            )
        )

        if !validID {
            neuroID.saveEventToDataStore(
                NIDEvent(
                    type: .log,
                    level: "ERROR",
                    m:
                        "Failed to save genericIdentifier of \(type.rawValue) event:\(scrubbedIdentifier)"
                )
            )
            return false
        }

        logger.d(tag: "\(type)", "\(identifier)")

        neuroID.saveEventToDataStore(
            NIDEvent(
                rawEventType: type == .sessionID
                    ? NIDSessionEventName.setUserId.rawValue
                    : type == .registeredUserID
                        ? NIDSessionEventName.setRegisteredUserId.rawValue
                        : NIDEventName.attemptedLogin.rawValue,
                uid: identifier
            )
        )

        validIDFunction()

        return true
    }

    func logScrubbedIdentityAttempt(
        identifier: String, message: String
    ) -> String {
        let scrubbedIdentifier = scrubIdentifier(identifier)
        neuroID.saveEventToDataStore(
            NIDEvent(
                type: .log,
                level: "INFO",
                m: "\(message): \(scrubbedIdentifier)"
            )
        )

        return scrubbedIdentifier
    }

    func scrubIdentifier(_ identifier: String) -> String {
        do {
            let emailRegex = try NSRegularExpression(
                pattern: "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}")
            let ssnRegex = try NSRegularExpression(
                pattern: "\\b\\d{3}-\\d{2}-\\d{4}\\b")
            var result = emailRegex.matches(
                in: identifier, range: NSMakeRange(0, identifier.count))
            if !result.isEmpty {
                let atIndex =
                    identifier.firstIndex(of: "@") ?? identifier.endIndex
                let idLength = identifier.distance(
                    from: identifier.startIndex, to: atIndex)
                let scrubbedEmailId =
                    String(identifier.prefix(1))
                    + String(repeating: "*", count: idLength - 1)
                    + identifier[atIndex...]
                return scrubbedEmailId
            }
            result = ssnRegex.matches(
                in: identifier, range: NSMakeRange(0, identifier.count))
            if !result.isEmpty {
                return "***-**-****"
            }
            return identifier
        } catch let error as NSError {
            logger.e("Invalid pattern: \(error.localizedDescription)")
            return identifier
        }
    }

    internal func validateIdentifier(_ identifier: String) -> Bool {
        // user ids must be from 3 to 100 ascii alhpa numeric characters and can include `.`, `-`, and `_`
        do {
            let expression = try NSRegularExpression(
                pattern: "^[a-zA-Z0-9-_.]{3,100}$",
                options: NSRegularExpression.Options(rawValue: 0))
            let result = expression.matches(
                in: identifier,
                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                range: NSMakeRange(0, identifier.count))
            if result.count != 1 {
                logger.e(NIDError.invalidUserID.rawValue)
                return false
            }
        } catch {
            logger.e(NIDError.invalidUserID.rawValue)
            return false
        }
        return true
    }

    internal func sendOriginEvent(_ originResult: SessionIDOriginalResult) {
        neuroID.saveEventToDataStore(
            NIDEvent(
                sessionEvent: .setVariable,
                key: "sessionIdCode",
                v: originResult.originCode
            )
        )
        neuroID.saveEventToDataStore(
            NIDEvent(
                sessionEvent: .setVariable,
                key: "sessionIdSource",
                v: originResult.origin
            )
        )
        neuroID.saveEventToDataStore(
            NIDEvent(
                sessionEvent: .setVariable,
                key: "sessionId",
                v: "\(originResult.idValue)"
            )
        )
        neuroID.saveEventToDataStore(
            NIDEvent(
                sessionEvent: .setVariable,
                key: "sessionIdType",
                v: originResult.idType.rawValue
            )
        )
    }

    internal func getOriginResult(
        idValue: String,
        validID: Bool,
        userGenerated: Bool,
        idType: UserIDTypes
    ) -> SessionIDOriginalResult {
        let origin =
            userGenerated
            ? SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue
            : SessionOrigin.NID_ORIGIN_NID_SET.rawValue
        var originCode = SessionOrigin.NID_ORIGIN_CODE_FAIL.rawValue
        if validID {
            originCode =
                userGenerated
                ? SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue
                : SessionOrigin.NID_ORIGIN_CODE_NID.rawValue
        }
        return SessionIDOriginalResult(
            origin: origin, originCode: originCode, idValue: idValue,
            idType: idType)
    }
}
