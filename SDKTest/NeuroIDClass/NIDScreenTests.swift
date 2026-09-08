//
//  NIDScreenTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//

import XCTest

@testable import NeuroID

class NIDScreenTests: BaseTestClass {
    var mockEventService = MockEventService()
    var neuroID = NeuroIDCore()

    override func setUp() {
        mockEventService = MockEventService()
        neuroID = NeuroIDCore(eventService: mockEventService)
    }

    // setScreenName
    // not started
    func test_setScreenName_not_started() {
        neuroID._isSDKStarted = false
        let expectedValue = "testScreen"

        let screenNameSet = NeuroID.setScreenName(expectedValue)

        assert(!screenNameSet)
        assert(neuroID._currentScreenName != expectedValue)
        assert(mockEventService.saveEventToLocalDataStoreCount == 0)
    }

    // started, url encode ok, mobile metadata captured
    func test_setScreenName_started_urlEncode() {
        neuroID._isSDKStarted = true
        let expectedValue = "testScreen"

        let screenNameSet = neuroID.setScreenName(expectedValue)

        assert(screenNameSet)
        assert(neuroID._currentScreenName == expectedValue)

        assert(mockEventService.saveEventToLocalDataStoreCount == 1)
        _ = assertStoredEventTypeAndCount(
            dataStoreEvents: mockEventService.mockEventStore,
            type: NIDEventName.mobileMetadataIOS.rawValue,
            count: 1
        )

        assert(mockEventService.saveEventToDataStoreCount == 1)
        _ = assertStoredEventTypeAndCount(
            dataStoreEvents: mockEventService.mockEventStore,
            type: NIDEventName.applicationMetadata.rawValue,
            count: 1
        )
    }

    func test_setScreenName_started_urlEncode_value() {
        neuroID._isSDKStarted = true
        let expectedValue = "test%20Screen"
        let screenNameSet = neuroID.setScreenName("test Screen")

        assert(screenNameSet)
        assert(neuroID._currentScreenName == expectedValue)

        assert(mockEventService.saveEventToLocalDataStoreCount == 1)
        _ = assertStoredEventTypeAndCount(
            dataStoreEvents: mockEventService.mockEventStore,
            type: NIDEventName.mobileMetadataIOS.rawValue,
            count: 1
        )

        assert(mockEventService.saveEventToDataStoreCount == 1)
        _ = assertStoredEventTypeAndCount(
            dataStoreEvents: mockEventService.mockEventStore,
            type: NIDEventName.applicationMetadata.rawValue,
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
