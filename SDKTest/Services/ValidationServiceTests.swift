//
//  ValidationServiceTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 1/27/25.
//

import Testing
@testable import NeuroID

@Suite("Validation Service Tests")
struct ValidationServiceTests {
    let validationService = ValidationService(
        logger: NIDLog()
    )

    // MARK: Client Key
    @Test(
        "Validate Site ID - Valid",
        arguments: [
            "key_live_XXXXXXXXXXX",  // LIVE
            "key_test_XXXXXXXXXXX",  // TEST
        ]
    )
    func validateClientKeySuccess(clientKey: String) {
        #expect(validationService.validateClientKey(clientKey))
    }

    @Test(
        "Validate Site ID - Invalid",
        arguments: [
            "key_foo_XXXXXXXXXXX",  // invalid
            "sdfsdfsdfsdf",  // random
            "",  // Empty
            "key_test_ABCDEFGHIG"
        ]
    )
    func validateClientKeyFail(clientKey: String) {
        #expect(!validationService.validateClientKey(clientKey))
    }

    // MARK: Site ID
    @Test(
        "Validate Site ID - Valid",
        arguments: [
            "form_peaks345"
        ]
    )
    func validateSiteIdSuccess(siteId: String) {
        #expect(validationService.validateSiteID(siteId))
    }

    @Test(
        "Validate Site ID - Invalid",
        arguments: [
            "form_abc123",  // too short
            "badSiteID",  // random
            "",  // Empty
        ]
    )
    func validateSiteIdFail(siteId: String) {
        #expect(!validationService.validateSiteID(siteId))
    }

    // MARK: ID
    @Test(
        "Validate ID - Valid",
        arguments: [
            "123",
            "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789",
            "a-A_1.0",
        ]
    )
    func validateIdentifierSuccess(id: String) {
        #expect(validationService.validateIdentifier(id))
    }

    @Test(
        "Validate ID - Invalid",
        arguments: [
            "",
            "1",
            "12",
            "to_long_789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789",
            "this_is_way_to_long_0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789",
            "invalid characters",
            "invalid*ch@racters",
        ]
    )
    func validateIdentifierFail(id: String) {
        #expect(!validationService.validateIdentifier(id))
    }
}
