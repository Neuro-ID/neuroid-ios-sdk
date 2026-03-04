//
//  NIDRNTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//

import XCTest

@testable import NeuroID

class NIDRNTests: XCTestCase {
    var neuroID = NeuroIDCore()

    override func setUp() {
        neuroID = NeuroIDCore()
        neuroID.isRN = false
    }

    func assertConfigureTests(defaultValue: Bool, expectedValue: Bool) {
        assert(NeuroIDCore.shared.isRN)
        let storedValue = NeuroIDCore.shared.rnOptions[.usingReactNavigation] as? Bool ?? defaultValue
        assert(storedValue == expectedValue)
        assert(NeuroIDCore.shared.rnOptions.count == 1)
    }

    // setIsRN
    func test_isRN() {
        assert(!neuroID.isRN)
        neuroID.setIsRN(hostRnVersion: "0.75.0")

        assert(neuroID.isRN)
        assert(neuroID.hostReactNativeVersion == "0.75.0")
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
        assert(neuroID.advancedDeviceKey == nil)
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
        assert(neuroID.advancedDeviceKey == nil)
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
        assert(neuroID.rnOptions.count == 1)
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
        assert(neuroID.advancedDeviceKey == nil)
        assert(neuroID.rnOptions[.usingReactNavigation] as! Bool == true)
    }
}
