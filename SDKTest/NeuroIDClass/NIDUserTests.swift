//
//  NIDUserTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//

@testable import NeuroID
import XCTest

class NIDUserTests: BaseTestClass {
    override func setUpWithError() throws {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    override func setUp() {
        NeuroID._isSDKStarted = true
        NeuroID._isTesting = true
        NeuroID.datastore = dataStore
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
        NeuroID._isTesting = false
    }

    func test_getSessionID_objectLevel() {
        let expectedValue = "test_uid"

        NeuroID.identifierService.sessionID = expectedValue

        let value = NeuroID.getSessionID()

        assert(NeuroID.sessionID == expectedValue)
        assert(value == expectedValue)
    }

    func test_getSessionID_dataStore() {
        let expectedValue = "test_uid"

        NeuroID.identifierService.sessionID = nil

        let value = NeuroID.getSessionID()

        assert(value == "")
        assert(NeuroID.sessionID != expectedValue)
    }

    func test_getRegisteredUserID_objectLevel() {
        let expectedValue = "test_uid"

        NeuroID.identifierService.registeredUserID = expectedValue

        let value = NeuroID.getRegisteredUserID()

        assert(NeuroID.registeredUserID == expectedValue)
        assert(value == expectedValue)

        NeuroID.identifierService.registeredUserID = ""
    }

    func test_attemptedLoginWthUID() {
        let validID = NeuroID.attemptedLogin("valid_user_id")

        assertStoredEventTypeAndCount(type: "ATTEMPTED_LOGIN", count: 1)
        assertStoredEventTypeAndCount(type: "LOG", count: 1)
        XCTAssertTrue(validID)
    }

    func test_attemptedLoginWthUIDQueued() {
        NeuroID._isSDKStarted = false
        let validID = NeuroID.attemptedLogin("valid_user_id")
        assertQueuedEventTypeAndCount(type: "ATTEMPTED_LOGIN", count: 1)
        assertQueuedEventTypeAndCount(type: "LOG", count: 1)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue, queued: true)

        let allEvents = NeuroID.datastore.getAndRemoveAllQueuedEvents()
        let event = allEvents.filter { $0.type == "ATTEMPTED_LOGIN" }

        XCTAssertTrue(validID)
        XCTAssertNotNil(event[0].uid!)
        // Value shoould be hashed/salted/prefixed
        XCTAssertEqual("valid_user_id", event[0].uid!)
    }

    func test_attemptedLoginWithInvalidID() {
        let invalidID = NeuroID.attemptedLogin("🤣")
        let allEvents = NeuroID.datastore.getAllEvents()
        let event = allEvents.filter { $0.type == "ATTEMPTED_LOGIN" }

        XCTAssert(event.count == 1)
        XCTAssertTrue(invalidID)
        XCTAssertEqual(event[0].uid, "scrubbed-id-failed-validation")
        assertStoredEventTypeAndCount(type: "LOG", count: 2)
    }

    func test_attemptedLoginWithInvalidIDQueued() {
        NeuroID._isSDKStarted = false
        let invalidID = NeuroID.attemptedLogin("🤣")

        assertQueuedEventTypeAndCount(type: "LOG", count: 2)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_FAIL.rawValue, queued: true)
        let allEvents = NeuroID.datastore.getAndRemoveAllQueuedEvents()
        let event = allEvents.filter { $0.type == "ATTEMPTED_LOGIN" }
        XCTAssert(event.count == 1)
        XCTAssertTrue(invalidID)
        XCTAssertEqual(event[0].uid, "scrubbed-id-failed-validation")
    }

    func test_attemptedLoginWithNoUID() {
        _ = NeuroID.attemptedLogin()

        assertStoredEventTypeAndCount(type: "ATTEMPTED_LOGIN", count: 1)
        assertStoredEventTypeAndCount(type: "LOG", count: 1)
    }

    func test_attemptedLoginWithNoUIDQueued() {
        NeuroID._isSDKStarted = false
        _ = NeuroID.attemptedLogin()
        assertQueuedEventTypeAndCount(type: "ATTEMPTED_LOGIN", count: 1)
        assertQueuedEventTypeAndCount(type: "LOG", count: 1)
        assertDatastoreEventOrigin(
            type: "SET_VARIABLE",
            origin: SessionOrigin.NID_ORIGIN_NID_SET.rawValue,
            originCode: SessionOrigin.NID_ORIGIN_CODE_NID.rawValue,
            queued: true
        )
        let allEvents = NeuroID.datastore.getAndRemoveAllQueuedEvents()
        let event = allEvents.filter { $0.type == "ATTEMPTED_LOGIN" }
        XCTAssertEqual(event.last!.uid, "scrubbed-id-failed-validation")
    }

    func test_multipleAttemptedLogins() {
        _ = NeuroID.attemptedLogin()
        _ = NeuroID.attemptedLogin()
        assertStoredEventTypeAndCount(type: "ATTEMPTED_LOGIN", count: 2)
        assertStoredEventTypeAndCount(type: "LOG", count: 2)
    }
}
