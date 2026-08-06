//
//  MockIdentifierService.swift
//  NeuroID
//
//  Created by Kevin Sites on 8/25/25.
//

@testable import NeuroID

class MockIdentifierService: IdentifierServiceProtocol {
    // Mock Vars
    var setIdentityIdResponse = false

    var setRegisteredIDResponse = false
    var setRegisteredUserIDCount = 0

    var setGenericIdentifierResponse = false
    var setGenericIdentifierCount = 0

    var clearIDsCount = 0

    var logScrubbedIdentityAttemptResponse = ""
    var logScrubbedIdentityAttemptCount = 0

    var scrubIdentifierResponse = ""
    var scrubIdentifierCount = 0

    func clearMocks() {
        setRegisteredIDResponse = false
        setRegisteredUserIDCount = 0

        setGenericIdentifierResponse = false
        setGenericIdentifierCount = 0

        clearIDsCount = 0

        logScrubbedIdentityAttemptResponse = ""
        logScrubbedIdentityAttemptCount = 0

        scrubIdentifierResponse = ""
        scrubIdentifierCount = 0
    }

    // Protocol Implementations
    var registeredUserID: String = ""

    func setIdentityId(_ identityId: String, _ userGenerated: Bool) -> Bool {
        return setIdentityIdResponse
    }

    func setRegisteredUserID(_ registeredUserID: String) -> Bool {
        setRegisteredUserIDCount += 1
        return setRegisteredIDResponse
    }

    func setGenericIdentifier(
        identifier: String,
        type: UserIDTypes,
        userGenerated: Bool,
        duplicatesAllowedCheck: (_ scrubbedIdentifier: String) -> Bool,
        validIDFunction: () -> Void
    ) -> Bool {
        setGenericIdentifierCount += 1
        return setGenericIdentifierResponse
    }

    func clearIDs() {
        clearIDsCount += 1
    }

    func logScrubbedIdentityAttempt(
        identifier: String, message: String
    ) -> String {
        logScrubbedIdentityAttemptCount += 1
        return logScrubbedIdentityAttemptResponse
    }

    func scrubIdentifier(_ identifier: String) -> String {
        scrubIdentifierCount += 1
        return scrubIdentifierResponse
    }
}
