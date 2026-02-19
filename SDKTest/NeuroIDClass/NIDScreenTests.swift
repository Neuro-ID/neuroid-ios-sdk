//
//  NIDScreenTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//

@testable import NeuroID
import XCTest

class NIDScreenTests: BaseTestClass {
    var mockEventStorageService = MockEventStorageService()
    var neuroID = NeuroIDCore()

    override func setUp() {
        mockEventStorageService = MockEventStorageService()
        neuroID = NeuroIDCore(eventStorageService: mockEventStorageService)
    }

    // setScreenName
    // not started
    func test_setScreenName_not_started() {
        neuroID._isSDKStarted = false
        let expectedValue = "testScreen"

        let screenNameSet = NeuroID.setScreenName(expectedValue)

        assert(!screenNameSet)
        assert(neuroID._currentScreenName != expectedValue)
        assert(mockEventStorageService.saveEventToLocalDataStoreCount == 0)
    }

    // started, url encode ok, mobile metadata captured
    func test_setScreenName_started_urlEncode() {
        neuroID._isSDKStarted = true
        let expectedValue = "testScreen"

        let screenNameSet = neuroID.setScreenName(expectedValue)

        assert(screenNameSet)
        assert(neuroID._currentScreenName == expectedValue)

        assert(mockEventStorageService.saveEventToLocalDataStoreCount == 1)
        _ = assertStoredEventTypeAndCount(
            dataStoreEvents: mockEventStorageService.mockEventStore,
            type: NIDEventName.mobileMetadataIOS.rawValue,
            count: 1
        )

        assert(mockEventStorageService.saveEventToDataStoreCount == 1)
        _ = assertStoredEventTypeAndCount(
            dataStoreEvents: mockEventStorageService.mockEventStore,
            type: NIDEventName.applicationMetaData.rawValue,
            count: 1
        )
    }

    func test_setScreenName_started_urlEncode_value() {
        neuroID._isSDKStarted = true
        let expectedValue = "test%20Screen"
        let screenNameSet = neuroID.setScreenName("test Screen")

        assert(screenNameSet)
        assert(neuroID._currentScreenName == expectedValue)

        assert(mockEventStorageService.saveEventToLocalDataStoreCount == 1)
        _ = assertStoredEventTypeAndCount(
            dataStoreEvents: mockEventStorageService.mockEventStore,
            type: NIDEventName.mobileMetadataIOS.rawValue,
            count: 1
        )

        assert(mockEventStorageService.saveEventToDataStoreCount == 1)
        _ = assertStoredEventTypeAndCount(
            dataStoreEvents: mockEventStorageService.mockEventStore,
            type: NIDEventName.applicationMetaData.rawValue,
            count: 1
        )
    }

    // getScreenName
    func test_getScreenName_exists() {
        let expectedValue = "testScreen"
        neuroID._currentScreenName = expectedValue

        let screenName = neuroID.getScreenName()

        assert(screenName == expectedValue)
    }

    func test_getScreenName_not_exists() {
        let expectedValue: String? = nil
        neuroID._currentScreenName = nil

        let screenName = neuroID.getScreenName()

        assert(screenName == expectedValue)
    }

    func test_getScreenName_empty() {
        let expectedValue: String? = ""
        neuroID._currentScreenName = ""

        let screenName = neuroID.getScreenName()

        assert(screenName == expectedValue)
    }
}
