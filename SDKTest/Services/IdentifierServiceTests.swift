//
//  IdentifierServiceTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 1/14/25.
//

import Foundation
@testable import NeuroID
import XCTest

class IdentifierServiceTests: BaseTestClass {
    var identifierService = IdentifierService(
        logger: NIDLog(),
        validationService: ValidationService(logger: NIDLog()),
        eventStorageService: EventStorageService()
    )

    override func setUpWithError() throws {
        // skip all tests in this class, remove this line to re-enabled tests
    }

    override func setUp() {
        clearOutDataStore()
        NeuroID._isTesting = true
        identifierService = IdentifierService(
            logger: NIDLog(),
            validationService: ValidationService(logger: NIDLog()),
            eventStorageService: EventStorageService()
        )

        NeuroID.identifierService = identifierService
    }

    override func tearDown() {
        clearOutDataStore()
        NeuroID._isTesting = false
    }

    func test_scrubEmailId() {
        let id = "tt@test.com"
        let expectedId = "t*@test.com"
        let scrubbedId = identifierService.scrubIdentifier(id)
        XCTAssertEqual(scrubbedId, expectedId)
    }

    func test_unScrubbedID() {
        let id = "123_testing123"
        let expectedId = "123_testing123"
        let unscrubbedId = identifierService.scrubIdentifier(id)
        XCTAssertEqual(unscrubbedId, expectedId)
    }

    func test_scrubSSN() {
        let id = "123-23-4568"
        let expectedId = "***-**-****"
        let scrubbedId = identifierService.scrubIdentifier(id)
        XCTAssertEqual(scrubbedId, expectedId)
    }

    func test_logScrubbedIdentityAttempt() {
        NeuroID._isSDKStarted = true
        clearOutDataStore()

        let id = "123-23-4568"
        let expectedId = "***-**-****"
        let scrubbedId = identifierService.logScrubbedIdentityAttempt(
            identifier: id,
            message: "Message Test"
        )
        XCTAssertEqual(scrubbedId, expectedId)
        assertStoredEventTypeAndCount(type: "LOG", count: 1)
    }

    func test_setGenericIdentifier_valid_id_started() {
        NeuroID._isSDKStarted = true
        clearOutDataStore()

        var successful = false
        let expectedValue = "myTestUserID"
        let result = identifierService.setGenericIdentifier(
            identifier: expectedValue,
            type: .sessionID,
            userGenerated: true,
            duplicatesAllowedCheck: { _ in true },
            validIDFunction: { successful = true }
        )

        assert(result == true)
        assert(successful == true)
        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
    }

    func test_setGenericIdentifier_valid_id_queued() {
        NeuroID._isSDKStarted = false
        clearOutDataStore()

        var successful = false
        let expectedValue = "myTestUserID"
        let result = identifierService.setGenericIdentifier(
            identifier: expectedValue,
            type: .sessionID,
            userGenerated: true,
            duplicatesAllowedCheck: { _ in true },
            validIDFunction: { successful = true }
        )

        assert(result == true)
        assert(successful == true)
        assert(NeuroID.datastore.events.count == 0)
        assertQueuedEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assertQueuedEventTypeAndCount(type: "SET_VARIABLE", count: 4)
    }

    func test_setGenericIdentifier_valid_registered_id_started() {
        NeuroID._isSDKStarted = true

        var successful = false
        let expectedValue = "myTestUserID"
        let result = identifierService.setGenericIdentifier(
            identifier: expectedValue,
            type: .registeredUserID,
            userGenerated: true,
            duplicatesAllowedCheck: { _ in true },
            validIDFunction: { successful = true }
        )

        assert(result == true)
        assert(successful == true)
        assertStoredEventTypeAndCount(type: "SET_REGISTERED_USER_ID", count: 1)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assert(NeuroID.datastore.queuedEvents.count == 0)
    }

    func test_setGenericIdentifier_valid_registered_id_queued() {
        NeuroID._isSDKStarted = false
        clearOutDataStore()

        var successful = false
        let expectedValue = "myTestUserID"
        let result = identifierService.setGenericIdentifier(
            identifier: expectedValue,
            type: .registeredUserID,
            userGenerated: true,
            duplicatesAllowedCheck: { _ in true },
            validIDFunction: { successful = true }
        )

        assert(result == true)
        assert(successful == true)
        assert(NeuroID.datastore.events.count == 0)
        assertQueuedEventTypeAndCount(type: "SET_REGISTERED_USER_ID", count: 1)
        assertQueuedEventTypeAndCount(type: "SET_VARIABLE", count: 4)
    }

    func test_setGenericIdentifier_invalid_id_started() {
        NeuroID._isSDKStarted = true
        clearOutDataStore()

        var successful = true
        let expectedValue = "$!&*"
        let result = identifierService.setGenericIdentifier(
            identifier: expectedValue,
            type: .sessionID,
            userGenerated: true,
            duplicatesAllowedCheck: { _ in true },
            validIDFunction: {
                successful = false
                assert(successful == false)
            }
        )

        assert(result == false)
        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 0, skipType: true)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
    }

    func test_setGenericIdentifier_invalid_id_queued() {
        NeuroID._isSDKStarted = false
        clearOutDataStore()

        var successful = true
        let expectedValue = "$!&*"
        let result = identifierService.setGenericIdentifier(
            identifier: expectedValue,
            type: .sessionID,
            userGenerated: true,
            duplicatesAllowedCheck: { _ in true },
            validIDFunction: {
                successful = false
                assert(successful == false)
            }
        )

        assert(result == false)
        assert(NeuroID.datastore.events.count == 0)
        assertQueuedEventTypeAndCount(type: "SET_USER_ID", count: 0, skipType: true)
        assertQueuedEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_FAIL.rawValue, queued: true)
    }

    func test_setSessionID_started_customer_origin() {
        NeuroID._isSDKStarted = true
        identifierService.sessionID = nil
        let expectedValue = "test_uid"

        let fnSuccess = identifierService.setSessionID(expectedValue, true)

        assert(fnSuccess)
        assert(NeuroID.sessionID == expectedValue)

        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
    }

    func test_setSessionID_pre_start_customer_origin() {
        _ = NeuroID.stop()
        identifierService.sessionID = nil

        let expectedValue = "test_uid"

        let fnSuccess = identifierService.setSessionID(expectedValue, true)

        assert(fnSuccess == true)
        assert(NeuroID.sessionID == expectedValue)

        //        assert(DataStore.events.count == 0) "NETWORK_STATE" event present
        assertQueuedEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assertQueuedEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue, queued: true)
    }

    func test_setSessionID_started_nid_origin() {
        identifierService.sessionID = nil
        NeuroID._isSDKStarted = true
        let expectedValue = "test_uid"

        let fnSuccess = identifierService.setSessionID(expectedValue, false)

        assert(fnSuccess)
        assert(NeuroID.sessionID == expectedValue)

        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assert(NeuroID.datastore.queuedEvents.count == 0)

        NeuroID._isSDKStarted = false
    }

    func test_setSessionID_pre_start_nid_origin() {
        _ = NeuroID.stop()
        identifierService.sessionID = nil

        let expectedValue = "test_uid"

        let fnSuccess = identifierService.setSessionID(expectedValue, false)

        assert(fnSuccess == true)
        assert(NeuroID.sessionID == expectedValue)
        assert(NeuroID.datastore.events.count == 0)
        assertQueuedEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assertQueuedEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_NID_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_NID.rawValue, queued: true)
    }

    func test_setRegisteredUserID_started() {
        clearOutDataStore()
        NeuroID._isSDKStarted = true
        let expectedValue = "test_ruid"
        identifierService.registeredUserID = ""

        let fnSuccess = identifierService.setRegisteredUserID(expectedValue)

        assert(fnSuccess == true)
        assert(NeuroID.registeredUserID == expectedValue)

        assertStoredEventTypeAndCount(type: "SET_REGISTERED_USER_ID", count: 1)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertStoredEventTypeAndCount(type: "LOG", count: 1)
        assert(NeuroID.datastore.queuedEvents.count == 0)

        identifierService.registeredUserID = ""

        NeuroID._isSDKStarted = false
    }

    func test_setRegisteredUserID_pre_start() {
        _ = NeuroID.stop()
        NeuroID._isSDKStarted = false
        clearOutDataStore()
        identifierService.registeredUserID = ""

        let expectedValue = "test_ruid"

        let fnSuccess = identifierService.setRegisteredUserID(expectedValue)

        assert(fnSuccess == true)
        assert(NeuroID.registeredUserID == expectedValue)

//        assert(DataStore.events.count == 0)
        assertQueuedEventTypeAndCount(type: "SET_REGISTERED_USER_ID", count: 1)
        assertQueuedEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue, queued: true)
        assertQueuedEventTypeAndCount(type: "LOG", count: 1)
        identifierService.registeredUserID = ""

        NeuroID._isSDKStarted = true
    }

    func test_setRegisteredUserID_already_set() {
        clearOutDataStore()
        NeuroID._isSDKStarted = true
        identifierService.registeredUserID = "setID"

        let expectedValue = "test_ruid"

        let fnSuccess = identifierService.setRegisteredUserID(expectedValue)

        assert(fnSuccess == true)
        assert(NeuroID.registeredUserID == expectedValue)

        assertStoredEventTypeAndCount(type: "LOG", count: 2)
        assert(NeuroID.datastore.queuedEvents.count == 0)

        identifierService.registeredUserID = ""
    }

    func test_setRegisteredUserID_same_value() {
        NeuroID._isSDKStarted = true
        clearOutDataStore()

        let expectedValue = "test_ruid"

        identifierService.registeredUserID = expectedValue

        let fnSuccess = identifierService.setRegisteredUserID(expectedValue)

        assert(fnSuccess == true)
        assert(NeuroID.registeredUserID == expectedValue)

        assertStoredEventTypeAndCount(type: "SET_REGISTERED_USER_ID", count: 1)

        identifierService.registeredUserID = ""
    }
}
