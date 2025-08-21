//
//  NIDRNTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//

@testable import NeuroID
import XCTest

class NIDRNTests: XCTestCase {
    override func setUp() {
        NeuroID.shared.isRN = false
        NeuroID.shared.clientKey = nil
    }

    let configOptionsTrue = [RNConfigOptions.usingReactNavigation.rawValue: true, RNConfigOptions.isAdvancedDevice.rawValue: false]
    let configOptionsFalse = [RNConfigOptions.usingReactNavigation.rawValue: false]
    let configOptionsInvalid = ["foo": "bar"]
    let configOptionsNonNil = [RNConfigOptions.advancedDeviceKey.rawValue: "testkey"]

    func assertConfigureTests(defaultValue: Bool, expectedValue: Bool) {
        assert(NeuroID.shared.isRN)
        let storedValue = NeuroID.shared.rnOptions[.usingReactNavigation] as? Bool ?? defaultValue
        assert(storedValue == expectedValue)
        assert(NeuroID.shared.rnOptions.count == 1)
    }

    func test_isRN() {
        assert(!NeuroID.shared.isRN)
        NeuroID.shared.setIsRN()

        assert(NeuroID.shared.isRN)
    }

    func test_configure_usingReactNavigation_true() {
        assert(!NeuroID.shared.isRN)
        let configured = NeuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: configOptionsTrue
        )

        assert(configured)
        assertConfigureTests(defaultValue: false, expectedValue: true)
    }

    func test_configure_usingReactNavigation_false() {
        assert(!NeuroID.shared.isRN)
        let configured = NeuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: configOptionsFalse
        )

        assert(configured)
        assertConfigureTests(defaultValue: true, expectedValue: false)
    }

    func test_configure_invalid_key() {
        assert(!NeuroID.shared.isRN)
        let configured = NeuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: configOptionsInvalid
        )

        assert(configured)
        assertConfigureTests(defaultValue: true, expectedValue: false)
    }

    func test_getOptionValueBool_true() {
        assert(!NeuroID.shared.isRN)
        let value = NeuroID.shared.getOptionValueBool(rnOptions: configOptionsTrue, configOptionKey: .usingReactNavigation)

        assert(value)
    }

    func test_getOptionValueBool_false() {
        assert(!NeuroID.shared.isRN)
        let value = NeuroID.shared.getOptionValueBool(rnOptions: configOptionsFalse, configOptionKey: .usingReactNavigation)

        assert(!value)
    }

    func test_getOptionValueBool_invalid() {
        assert(!NeuroID.shared.isRN)
        let value = NeuroID.shared.getOptionValueBool(rnOptions: configOptionsInvalid, configOptionKey: .usingReactNavigation)

        assert(!value)
    }

    func test_getOptionValueString_nonNil() {
        assert(!NeuroID.shared.isRN)
        let value = NeuroID.shared.getOptionValueString(rnOptions: configOptionsNonNil, configOptionKey: .advancedDeviceKey)

        assert(value == "testkey")
    }

    func test_getOptionValueString_nil() {
        assert(!NeuroID.shared.isRN)
        // does not contain advanced device key, therfore nil
        let value = NeuroID.shared.getOptionValueString(rnOptions: configOptionsFalse, configOptionKey: .advancedDeviceKey)

        assert(value == "")
    }
}
