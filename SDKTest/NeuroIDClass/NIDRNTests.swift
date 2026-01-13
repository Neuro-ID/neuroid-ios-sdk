//
//  NIDRNTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//

@testable import NeuroID
import Testing

@Suite("React Native Tests")
struct NIDRNTests {
    var neuroID = NeuroID()

    init() {
        neuroID = NeuroID()
        neuroID.isRN = false
    }

    // setIsRN
    @Test func isRN() {
        #expect(!neuroID.isRN)
        neuroID.setIsRN()

        #expect(neuroID.isRN)
    }

    // configure
    // configure - clientKey, not advanced, not adv key, not React nav
    @Test func configure_noAdv_noAdvKey_noRNav() {
        let configured = neuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: [:]
        )

        #expect(configured)
        #expect(!neuroID.isAdvancedDevice)
        #expect(neuroID.advancedDeviceKey == "")
        #expect(neuroID.rnOptions[.usingReactNavigation] as! Bool == false)
    }

    // configure - client key, advanced, not adv key, not react nav
    @Test func configure_Adv_noAdvKey_noRNav() {
        let configured = neuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: [
                RNConfigOptions.isAdvancedDevice.rawValue: true
            ]
        )

        #expect(configured)
        #expect(neuroID.isAdvancedDevice)
        #expect(neuroID.advancedDeviceKey == "")
        #expect(neuroID.rnOptions[.usingReactNavigation] as! Bool == false)
    }

    // configure - client key, advanced, adv key, not react nav
    @Test func configure_Adv_AdvKey_noRNav() {
        let expected = "testKey"
        let configured = neuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: [
                RNConfigOptions.isAdvancedDevice.rawValue: true,
                RNConfigOptions.advancedDeviceKey.rawValue: expected
            ]
        )

        #expect(configured)
        #expect(neuroID.isAdvancedDevice)
        #expect(neuroID.advancedDeviceKey == expected)
        #expect(neuroID.rnOptions[.usingReactNavigation] as! Bool == false)
    }

    // configure - client key, advanced, adv key, react nav
    @Test func configure_Adv_AdvKey_RNav() {
        let expected = "testKey"
        let configured = neuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: [
                RNConfigOptions.isAdvancedDevice.rawValue: true,
                RNConfigOptions.advancedDeviceKey.rawValue: expected,
                RNConfigOptions.usingReactNavigation.rawValue: true
            ]
        )

        #expect(configured)
        #expect(neuroID.isAdvancedDevice)
        #expect(neuroID.advancedDeviceKey == expected)
        #expect(neuroID.rnOptions[.usingReactNavigation] as! Bool == true)
    }

    // configure - invalid client key
    @Test func configure_invalid_clientKey() {
        let expected = "testKey"
        let configured = neuroID.configure(
            clientKey: "invalidKey",
            rnOptions: [
                RNConfigOptions.isAdvancedDevice.rawValue: true,
                RNConfigOptions.advancedDeviceKey.rawValue: expected,
                RNConfigOptions.usingReactNavigation.rawValue: true
            ]
        )

        #expect(!configured)
        #expect(!neuroID.isAdvancedDevice)
        #expect(neuroID.advancedDeviceKey == nil)
        #expect(neuroID.rnOptions.count == 0)
    }

    // configure - client key, not advanced, not adv key, react nav
    @Test func configure_no_Adv_no_AdvKey_RNav() {
        let configured = neuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: [
                RNConfigOptions.usingReactNavigation.rawValue: true
            ]
        )

        #expect(configured)
        #expect(!neuroID.isAdvancedDevice)
        #expect(neuroID.advancedDeviceKey == "")
        #expect(neuroID.rnOptions[.usingReactNavigation] as! Bool == true)
    }

    // getOptionValueBool
    @Test func getOptionValueBool_true() {
        let value = neuroID.getOptionValueBool(
            rnOptions: [
                RNConfigOptions.usingReactNavigation.rawValue: true,
                RNConfigOptions.isAdvancedDevice.rawValue: false
            ],
            configOptionKey: .usingReactNavigation
        )

        #expect(value)
    }

    @Test func getOptionValueBool_false() {
        let value = neuroID.getOptionValueBool(
            rnOptions: [RNConfigOptions.usingReactNavigation.rawValue: false],
            configOptionKey: .usingReactNavigation
        )

        #expect(!value)
    }

    @Test func getOptionValueBool_invalid() {
        let value = neuroID.getOptionValueBool(
            rnOptions: ["foo": "bar"],
            configOptionKey: .usingReactNavigation
        )

        #expect(!value)
    }

    // getOptionValueString
    @Test func getOptionValueString_nonNil() {
        let value = neuroID.getOptionValueString(
            rnOptions: [RNConfigOptions.advancedDeviceKey.rawValue: "testkey"],
            configOptionKey: .advancedDeviceKey
        )

        #expect(value == "testkey")
    }

    @Test func getOptionValueString_nil() {
        // does not contain advanced device key, therfore nil
        let value = neuroID.getOptionValueString(
            rnOptions: [:],
            configOptionKey: .advancedDeviceKey
        )

        #expect(value == "")
    }

    @Test func getOptionValueString_invalid() {
        // does not contain advanced device key, therfore nil
        let value = neuroID.getOptionValueString(
            rnOptions: [RNConfigOptions.advancedDeviceKey.rawValue: false],
            configOptionKey: .advancedDeviceKey
        )

        #expect(value == "")
    }
}
