//
//  NIDRNTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//

@testable import NeuroID
import XCTest

class NIDRNTests: XCTestCase {
    var neuroID = NeuroID()

    override func setUp() {
        neuroID = NeuroID()
        neuroID.isRN = false
    }

    func assertConfigureTests(defaultValue: Bool, expectedValue: Bool) {
        assert(NeuroID.shared.isRN)
        let storedValue = NeuroID.shared.rnOptions[.usingReactNavigation] as? Bool ?? defaultValue
        assert(storedValue == expectedValue)
        assert(NeuroID.shared.rnOptions.count == 1)
    }

    // setIsRN
    func test_isRN() {
        assert(!neuroID.isRN)
        neuroID.setIsRN()

        assert(neuroID.isRN)
    }

    // configure
    // configure - clientKey, not advanced, not adv key, not React nav
    func test_configure_noAdv_noAdvKey_noRNav() {
        let configured = neuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: [:]
        )

        assert(configured)
        assert(!neuroID.isAdvancedDevice)
        assert(neuroID.advancedDeviceKey == "")
        assert(neuroID.rnOptions[.usingReactNavigation] as! Bool == false)
    }

    // configure - client key, advanced, not adv key, not react nav
    func test_configure_Adv_noAdvKey_noRNav() {
        let configured = neuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: [
                RNConfigOptions.isAdvancedDevice.rawValue: true
            ]
        )

        assert(configured)
        assert(neuroID.isAdvancedDevice)
        assert(neuroID.advancedDeviceKey == "")
        assert(neuroID.rnOptions[.usingReactNavigation] as! Bool == false)
    }

    // configure - client key, advanced, adv key, not react nav
    func test_configure_Adv_AdvKey_noRNav() {
        let expected = "testKey"
        let configured = neuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: [
                RNConfigOptions.isAdvancedDevice.rawValue: true,
                RNConfigOptions.advancedDeviceKey.rawValue: expected
            ]
        )

        assert(configured)
        assert(neuroID.isAdvancedDevice)
        assert(neuroID.advancedDeviceKey == expected)
        assert(neuroID.rnOptions[.usingReactNavigation] as! Bool == false)
    }

    // configure - client key, advanced, adv key, react nav
    func test_configure_Adv_AdvKey_RNav() {
        let expected = "testKey"
        let configured = neuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: [
                RNConfigOptions.isAdvancedDevice.rawValue: true,
                RNConfigOptions.advancedDeviceKey.rawValue: expected,
                RNConfigOptions.usingReactNavigation.rawValue: true
            ]
        )

        assert(configured)
        assert(neuroID.isAdvancedDevice)
        assert(neuroID.advancedDeviceKey == expected)
        assert(neuroID.rnOptions[.usingReactNavigation] as! Bool == true)
    }

    // configure - invalid client key
    func test_configure_invalid_clientKey() {
        let expected = "testKey"
        let configured = neuroID.configure(
            clientKey: "invalidKey",
            rnOptions: [
                RNConfigOptions.isAdvancedDevice.rawValue: true,
                RNConfigOptions.advancedDeviceKey.rawValue: expected,
                RNConfigOptions.usingReactNavigation.rawValue: true
            ]
        )

        assert(!configured)
        assert(!neuroID.isAdvancedDevice)
        assert(neuroID.advancedDeviceKey == nil)
        assert(neuroID.rnOptions.count == 0)
    }

    // configure - client key, not advanced, not adv key, react nav
    func test_configure_no_Adv_no_AdvKey_RNav() {
        let configured = neuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: [
                RNConfigOptions.usingReactNavigation.rawValue: true
            ]
        )

        assert(configured)
        assert(!neuroID.isAdvancedDevice)
        assert(neuroID.advancedDeviceKey == "")
        assert(neuroID.rnOptions[.usingReactNavigation] as! Bool == true)
    }

    // getOptionValueBool
    func test_getOptionValueBool_true() {
        let value = neuroID.getOptionValueBool(
            rnOptions: [
                RNConfigOptions.usingReactNavigation.rawValue: true,
                RNConfigOptions.isAdvancedDevice.rawValue: false
            ],
            configOptionKey: .usingReactNavigation
        )

        assert(value)
    }

    func test_getOptionValueBool_false() {
        let value = neuroID.getOptionValueBool(
            rnOptions: [RNConfigOptions.usingReactNavigation.rawValue: false],
            configOptionKey: .usingReactNavigation
        )

        assert(!value)
    }

    func test_getOptionValueBool_invalid() {
        let value = neuroID.getOptionValueBool(
            rnOptions: ["foo": "bar"],
            configOptionKey: .usingReactNavigation
        )

        assert(!value)
    }

    // getOptionValueString
    func test_getOptionValueString_nonNil() {
        let value = neuroID.getOptionValueString(
            rnOptions: [RNConfigOptions.advancedDeviceKey.rawValue: "testkey"],
            configOptionKey: .advancedDeviceKey
        )

        assert(value == "testkey")
    }

    func test_getOptionValueString_nil() {
        // does not contain advanced device key, therfore nil
        let value = neuroID.getOptionValueString(
            rnOptions: [:],
            configOptionKey: .advancedDeviceKey
        )

        assert(value == "")
    }

    func test_getOptionValueString_invalid() {
        // does not contain advanced device key, therfore nil
        let value = neuroID.getOptionValueString(
            rnOptions: [RNConfigOptions.advancedDeviceKey.rawValue: false],
            configOptionKey: .advancedDeviceKey
        )

        assert(value == "")
    }
}
