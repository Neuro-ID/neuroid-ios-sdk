//
//  NIDScreenTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//

@testable import NeuroID
import XCTest

class NIDScreenTests: BaseTestClass {
    override func setUpWithError() throws {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
    }

    override func setUp() {
        NeuroID.shared._isSDKStarted = true
        NeuroID._isTesting = true
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
        NeuroID._isTesting = false
    }

    func test_setScreenName_getScreenName() {
        clearOutDataStore()
        let expectedValue = "testScreen"
        let screenNameSet = NeuroID.setScreenName(expectedValue)

        let value = NeuroID.getScreenName()

        assert(value == expectedValue)
        assert(screenNameSet == true)

        assertStoredEventTypeAndCount(type: "MOBILE_METADATA_IOS", count: 1)
    }

    func test_setScreenName_getScreenName_withSpace() {
        clearOutDataStore()
        let expectedValue = "test Screen"
        let screenNameSet = NeuroID.setScreenName(expectedValue)

        let value = NeuroID.getScreenName()

        assert(value == "test%20Screen")
        assert(screenNameSet == true)

        assertStoredEventTypeAndCount(type: "MOBILE_METADATA_IOS", count: 1)
    }

    func test_setScreenName_not_started() {
        clearOutDataStore()
        NeuroID.shared._isSDKStarted = false
        NeuroID.shared._currentScreenName = ""
        let expectedValue = "test Screen"
        let screenNameSet = NeuroID.setScreenName(expectedValue)

        let value = NeuroID.getScreenName()

        assert(value != "test%20Screen")
        assert(screenNameSet == false)

        let allEvents = NeuroID.shared.datastore.getAllEvents()
        assert(allEvents.count == 0)
    }
}
