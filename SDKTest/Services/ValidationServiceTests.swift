//
//  ValidationServiceTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 1/27/25.
//

import Foundation
@testable import NeuroID

class ValidationServiceTests: BaseTestClass {
    let validationService = ValidationService()

    func test_validateClientKey_valid_live() {
        let value = validationService.validateClientKey("key_live_XXXXXXXXXXX")

        assert(value)
    }

    func test_validateClientKey_valid_test() {
        let value = validationService.validateClientKey("key_test_XXXXXXXXXXX")

        assert(value)
    }

    func test_validateClientKey_invalid_env() {
        let value = validationService.validateClientKey("key_foo_XXXXXXXXXXX")

        assert(!value)
    }

    func test_validateClientKey_invalid_random() {
        let value = validationService.validateClientKey("sdfsdfsdfsdf")

        assert(!value)
    }

    func test_validateSiteID_valid() {
        let value = validationService.validateSiteID("form_peaks345")

        assert(value)
    }

    func test_validateSiteID_invalid_bad() {
        let value = validationService.validateSiteID("badSiteID")

        assert(!value)
    }

    func test_validateSiteID_invalid_short() {
        let value = validationService.validateSiteID("form_abc123")

        assert(!value)
    }

    func test_validatedIdentifiers_valid_id() {
        let validIdentifiers = [
            "123",
            "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789",
            "a-A_1.0",
        ]

        for identifier in validIdentifiers {
            let userNameSet = validationService.validateIdentifier(identifier)
            assert(userNameSet == true)
        }
    }

    func test_validatedIdentifiers_invalid_id() {
        let invalidIdentifiers = [
            "",
            "1",
            "12",
            "to_long_789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789",
            "this_is_way_to_long_0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789",
            "invalid characters",
            "invalid*ch@racters",
        ]

        for identifier in invalidIdentifiers {
            let userNameSet = validationService.validateIdentifier(identifier)
            assert(userNameSet == false)
        }
    }

//    validateIdentifier
}
