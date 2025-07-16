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
        NeuroID.isRN = false
        NeuroID.clientKey = nil
    }

    let configOptionsTrue = [RNConfigOptions.usingReactNavigation.rawValue: true, RNConfigOptions.isAdvancedDevice.rawValue: false]
    let configOptionsFalse = [RNConfigOptions.usingReactNavigation.rawValue: false]
    let configOptionsInvalid = ["foo": "bar"]
    let configOptionsNonNil = [RNConfigOptions.advancedDeviceKey.rawValue: "testkey"]

    func assertConfigureTests(defaultValue: Bool, expectedValue: Bool) {
        assert(NeuroID.isRN)
        let storedValue = NeuroID.rnOptions[.usingReactNavigation] as? Bool ?? defaultValue
        assert(storedValue == expectedValue)
        assert(NeuroID.rnOptions.count == 1)
    }

    func test_isRN() {
        assert(!NeuroID.isRN)
        NeuroID.setIsRN()

        assert(NeuroID.isRN)
    }

    func test_configure_usingReactNavigation_true() {
        assert(!NeuroID.isRN)
        let configured = NeuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: configOptionsTrue
        )

        assert(configured)
        assertConfigureTests(defaultValue: false, expectedValue: true)
    }

    func test_configure_usingReactNavigation_false() {
        assert(!NeuroID.isRN)
        let configured = NeuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: configOptionsFalse
        )

        assert(configured)
        assertConfigureTests(defaultValue: true, expectedValue: false)
    }

    func test_configure_invalid_key() {
        assert(!NeuroID.isRN)
        let configured = NeuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: configOptionsInvalid
        )

        assert(configured)
        assertConfigureTests(defaultValue: true, expectedValue: false)
    }

    func test_getOptionValueBool_true() {
        assert(!NeuroID.isRN)
        let value = NeuroID.getOptionValueBool(rnOptions: configOptionsTrue, configOptionKey: .usingReactNavigation)

        assert(value)
    }

    func test_getOptionValueBool_false() {
        assert(!NeuroID.isRN)
        let value = NeuroID.getOptionValueBool(rnOptions: configOptionsFalse, configOptionKey: .usingReactNavigation)

        assert(!value)
    }

    func test_getOptionValueBool_invalid() {
        assert(!NeuroID.isRN)
        let value = NeuroID.getOptionValueBool(rnOptions: configOptionsInvalid, configOptionKey: .usingReactNavigation)

        assert(!value)
    }

    func test_getOptionValueString_nonNil() {
        assert(!NeuroID.isRN)
        let value = NeuroID.getOptionValueString(rnOptions: configOptionsNonNil, configOptionKey: .advancedDeviceKey)

        assert(value == "testkey")
    }

    func test_getOptionValueString_nil() {
        assert(!NeuroID.isRN)
        // does not contain advanced device key, therfore nil
        let value = NeuroID.getOptionValueString(rnOptions: configOptionsFalse, configOptionKey: .advancedDeviceKey)

        assert(value == "")
    }
}
