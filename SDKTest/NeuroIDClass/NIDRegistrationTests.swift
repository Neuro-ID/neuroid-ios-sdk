//
//  NIDRegistrationTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//

@testable import NeuroID
import XCTest

class NIDRegistrationTests: BaseTestClass {
    override func setUpWithError() throws {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
    }

    override func setUp() {
        NeuroID._isSDKStarted = true
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    func test_excludeViewByTestID() {
        clearOutDataStore()
        NeuroID.excludedViewsTestIDs = []
        let expectedValue = "testScreenName"

        NeuroID.excludeViewByTestID(excludedView: expectedValue)

        let contains = NeuroID.excludedViewsTestIDs.contains(where: { $0 == expectedValue })
        assert(contains)

        assert(NeuroID.excludedViewsTestIDs.count == 1)
    }

    func test_manuallyRegisterTarget_valid_type() {
        clearOutDataStore()
        let uiView = UITextField()
        uiView.id = "wow"

        NeuroID.manuallyRegisterTarget(view: uiView)

        assertStoredEventTypeAndCount(type: "REGISTER_TARGET", count: 1)

        let allEvents = NeuroID.datastore.getAllEvents()
        let validEvents = allEvents.filter { $0.type == "REGISTER_TARGET" }
        assert(validEvents[0].tgs == "wow")
        assert(validEvents[0].et == "UITextField::UITextField")
    }

    func test_manuallyRegisterTarget_invalid_type() {
        clearOutDataStore()
        let uiView = UIView()

        NeuroID.manuallyRegisterTarget(view: uiView)

        assertDataStoreCount(count: 0)
    }

    func test_manuallyRegisterRNTarget() {
        clearOutDataStore()

        let event = NeuroID.manuallyRegisterRNTarget(
            id: "test",
            className: "testClassName",
            screenName: "testScreenName",
            placeHolder: "testPlaceholder"
        )

        assert(event.tgs == "test")
        assert(event.et == "testClassName")
        assert(event.etn == "INPUT")

        assertStoredEventTypeAndCount(type: "REGISTER_TARGET", count: 1)
    }

    func test_setCustomVariable() {
        clearOutDataStore()
        let event = NeuroID.setCustomVariable(key: "t", v: "v")

        XCTAssertTrue(event.type == NIDEventName.setVariable.rawValue)
        XCTAssertTrue(event.key == "t")
        XCTAssertTrue(event.v == "v")

        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 1)
    }

    func test_setVariable() {
        clearOutDataStore()
        let event = NeuroID.setVariable(key: "t", value: "v")

        XCTAssertTrue(event.type == NIDEventName.setVariable.rawValue)
        XCTAssertTrue(event.key == "t")
        XCTAssertTrue(event.v == "v")
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 1)
    }
}
