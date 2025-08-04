//
//  IdentifierService.swift
//  NeuroID
//
//  Created by Kevin Sites on 1/14/25.
//

import Foundation

protocol IdentifierServiceProtocol {
    var sessionID: String? { get set } // Formerly known as userID, now within the mobile sdk ONLY sessionID
    var registeredUserID: String { get set }

    func setSessionID(_ sessionID: String, _ userGenerated: Bool) -> Bool
    func setRegisteredUserID(_ registeredUserID: String) -> Bool

    func setGenericIdentifier(
        identifier: String,
        type: UserIDTypes,
        userGenerated: Bool,
        duplicatesAllowedCheck: (_ scrubbedIdentifier: String) -> Bool,
        validIDFunction: () -> Void
    ) -> Bool

    func clearIDs()

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
    let logger: NIDLog
    let validationService: ValidationService
    let eventStorageService: EventStorageProtocol

    var sessionID: String? // Formerly known as userID, now within the mobile sdk ONLY sessionID
    var registeredUserID: String = ""

    init(
        logger: NIDLog,
        validationService: ValidationService,
        eventStorageService: EventStorageProtocol
    ) {
        self.logger = logger
        self.validationService = validationService
        self.eventStorageService = eventStorageService
    }

    // This command replaces `setUserID` (internal version)
    func setSessionID(_ sessionID: String, _ userGenerated: Bool) -> Bool {
        let validID = setGenericIdentifier(
            identifier: sessionID,
            type: .sessionID,
            userGenerated: userGenerated,
            duplicatesAllowedCheck: { _ in true }
        ) {
            self.sessionID = sessionID
        }

        return validID
    }

    func setRegisteredUserID(_ registeredUserID: String) -> Bool {
        let validID = setGenericIdentifier(
            identifier: registeredUserID,
            type: .registeredUserID,
            duplicatesAllowedCheck: { scrubbedIdentifier in
                if !self.registeredUserID.isEmpty,
                   registeredUserID != self.registeredUserID
                {
                    self.eventStorageService.saveEventToLocalDataStore(
                        NIDEvent(
                            type: .log,
                            level: "WARN",
                            m:
                            "Multiple Registered UserID Attempt - existing:\(self.registeredUserID) new:\(scrubbedIdentifier)"
                        )
                    )

                    logger.e(
                        "Multiple Registered UserID Attempt: Only 1 Registered UserID can be set per session"
                    )
                }
                return true
            }
        ) {
            self.registeredUserID = registeredUserID
        }

        return validID
    }

    func setGenericIdentifier(
        identifier: String,
        type: UserIDTypes,
        userGenerated: Bool = true,
        duplicatesAllowedCheck: (_ scrubbedIdentifier: String) -> Bool = { _ in
            true
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

        let validID = validationService.validateIdentifier(identifier)

        sendOriginEvent(
            getOriginResult(
                idValue: identifier,
                validID: validID,
                userGenerated: userGenerated,
                idType: type
            )
        )

        if !validID {
            eventStorageService.saveEventToDataStore(
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

        eventStorageService.saveEventToDataStore(
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

    func clearIDs() {
        sessionID = nil
        registeredUserID = ""
    }

    func logScrubbedIdentityAttempt(
        identifier: String, message: String
    ) -> String {
        let scrubbedIdentifier = scrubIdentifier(identifier)
        eventStorageService.saveEventToDataStore(
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
            var result = emailRegex.matches(
                in: identifier, range: NSMakeRange(0, identifier.count)
            )
            if !result.isEmpty {
                let atIndex =
                    identifier.firstIndex(of: "@") ?? identifier.endIndex
                let idLength = identifier.distance(
                    from: identifier.startIndex, to: atIndex
                )
                let scrubbedEmailId =
                    String(identifier.prefix(1))
                        + String(repeating: "*", count: idLength - 1)
                        + identifier[atIndex...]
                return scrubbedEmailId
            }

            let ssnRegex = try NSRegularExpression(
                pattern: "\\b\\d{3}-\\d{2}-\\d{4}\\b")
            result = ssnRegex.matches(
                in: identifier, range: NSMakeRange(0, identifier.count)
            )
            if !result.isEmpty {
                return "***-**-****"
            }
            return identifier
        } catch let error as NSError {
            logger.e("Invalid pattern: \(error.localizedDescription)")
            return identifier
        }
    }

    func sendOriginEvent(_ originResult: SessionIDOriginalResult) {
        eventStorageService.saveEventToDataStore(
            NIDEvent(
                sessionEvent: .setVariable,
                key: "sessionIdCode",
                v: originResult.originCode
            )
        )
        eventStorageService.saveEventToDataStore(
            NIDEvent(
                sessionEvent: .setVariable,
                key: "sessionIdSource",
                v: originResult.origin
            )
        )
        eventStorageService.saveEventToDataStore(
            NIDEvent(
                sessionEvent: .setVariable,
                key: "sessionId",
                v: "\(originResult.idValue)"
            )
        )
        eventStorageService.saveEventToDataStore(
            NIDEvent(
                sessionEvent: .setVariable,
                key: "sessionIdType",
                v: originResult.idType.rawValue
            )
        )
    }

    func getOriginResult(
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
            idType: idType
        )
    }
}
