//
//  IdentifierServiceTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 1/14/25.
//

import Foundation
import XCTest
@testable import NeuroID

class IdentifierServiceTests: BaseTestClass {
    var identifierService = IdentifierService(of: NeuroID.self, of: NIDLog.self, validationService: ValidationService(loggerType: NIDLog.self))

    override func setUp() {
        clearOutDataStore()
        identifierService = IdentifierService(of: NeuroID.self, of: NIDLog.self, validationService: ValidationService(loggerType: NIDLog.self))
    }

    override func tearDown() {
        clearOutDataStore()
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
            message: "Message Test")
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
            duplicatesAllowedCheck: {_ in return true},
            validIDFunction: { successful = true }
        )
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)
        
        assert(result == true)
        assert(successful == true)
        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 0)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 0)
        assert(NeuroID.datastore.queuedEvents.count == 0)
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
            duplicatesAllowedCheck: {_ in return true},
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
            duplicatesAllowedCheck: {_ in return true},
            validIDFunction: { successful = true }
        )
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)

        assert(result == true)
        assert(successful == true)
        assertStoredEventTypeAndCount(type: "SET_REGISTERED_USER_ID", count: 0)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 0)
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
            duplicatesAllowedCheck: {_ in return true},
            validIDFunction: { successful = true }
        )
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)

        assert(result == true)
        assert(successful == true)
        assert(NeuroID.datastore.events.count == 0)
        assertQueuedEventTypeAndCount(type: "SET_REGISTERED_USER_ID", count: 1)
        assertQueuedEventTypeAndCount(type: "SET_VARIABLE", count: 4)
    }

    func test_setGenericIdentifier_invalid_id_started() {
        NeuroID._isSDKStarted = true
        clearOutDataStore()
     
        var successful = false
        let expectedValue = "$!&*"
        let result = identifierService.setGenericIdentifier(
            identifier: expectedValue,
            type: .sessionID,
            userGenerated: true,
            duplicatesAllowedCheck: {_ in return true},
            validIDFunction: { successful = false }
        )
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)

        assert(result == false)
        assert(successful == false)
        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 0, skipType: true)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 0)
    }

    func test_setGenericIdentifier_invalid_id_queued() {
        NeuroID._isSDKStarted = false
        clearOutDataStore()

        var successful = false
        let expectedValue = "$!&*"
        let result = identifierService.setGenericIdentifier(
            identifier: expectedValue,
            type: .sessionID,
            userGenerated: true,
            duplicatesAllowedCheck: {_ in return true},
            validIDFunction: { successful = false }
        )
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)

        assert(result == false)
        assert(successful == false)
        assert(NeuroID.datastore.events.count == 0)
        assertQueuedEventTypeAndCount(type: "SET_USER_ID", count: 0, skipType: true)
        assertQueuedEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_FAIL.rawValue, queued: true)
    }

    func test_setSessionID_started_customer_origin() {
        NeuroID._isSDKStarted = true
        NeuroID.sessionID = nil
        let expectedValue = "test_uid"

        let fnSuccess = identifierService.setSessionID(expectedValue, true)
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)

        assert(fnSuccess)
        assert(NeuroID.sessionID == expectedValue)

        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 0)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 0)
        assert(NeuroID.datastore.events.count == 0)
    }

    func test_setSessionID_pre_start_customer_origin() {
        _ = NeuroID.stop()
        NeuroID.sessionID = nil

        let expectedValue = "test_uid"

        let fnSuccess = identifierService.setSessionID(expectedValue, true)
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)

        assert(fnSuccess == true)
        assert(NeuroID.sessionID == expectedValue)

        //        assert(DataStore.events.count == 0) "NETWORK_STATE" event present
        assertQueuedEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assertQueuedEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue, queued: true)
    }

    func test_setSessionID_started_nid_origin() {
        NeuroID.sessionID = nil
        let expectedValue = "test_uid"

        let fnSuccess = identifierService.setSessionID(expectedValue, false)
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)

        assert(fnSuccess)
        assert(NeuroID.sessionID == expectedValue)

        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 0)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 0)
        assert(NeuroID.datastore.events.count == 0)
    }

    func test_setSessionID_pre_start_nid_origin() {
        _ = NeuroID.stop()
        NeuroID.sessionID = nil

        let expectedValue = "test_uid"

        let fnSuccess = identifierService.setSessionID(expectedValue, false)
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)

        assert(fnSuccess == true)
        assert(NeuroID.sessionID == expectedValue)
        assert(NeuroID.datastore.events.count == 0)
        assertQueuedEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assertQueuedEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_NID_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_NID.rawValue, queued: true)
    }


    func test_setRegisteredUserID_started() {
        let expectedValue = "test_ruid"
        NeuroID.registeredUserID = ""

        let fnSuccess = identifierService.setRegisteredUserID(expectedValue)
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)

        assert(fnSuccess == true)
        assert(NeuroID.registeredUserID == expectedValue)

        assertStoredEventTypeAndCount(type: "SET_REGISTERED_USER_ID", count: 0)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 0)
        assertStoredEventTypeAndCount(type: "LOG", count: 0)
        assert(NeuroID.datastore.queuedEvents.count == 0)

        NeuroID.registeredUserID = ""
    }

    func test_setRegisteredUserID_pre_start() {
        _ = NeuroID.stop()
        NeuroID.registeredUserID = ""

        let expectedValue = "test_ruid"

        let fnSuccess = identifierService.setRegisteredUserID(expectedValue)
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)

        assert(fnSuccess == true)
        assert(NeuroID.registeredUserID == expectedValue)

//        assert(DataStore.events.count == 0)
        assertQueuedEventTypeAndCount(type: "SET_REGISTERED_USER_ID", count: 1)
        assertQueuedEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue, queued: true)
        assertQueuedEventTypeAndCount(type: "LOG", count: 1)
        NeuroID.registeredUserID = ""
    }

    func test_setRegisteredUserID_already_set() {
        clearOutDataStore()
        NeuroID._isSDKStarted = true
        NeuroID.registeredUserID = "setID"

        let expectedValue = "test_ruid"

        let fnSuccess = identifierService.setRegisteredUserID(expectedValue)
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)

        assert(fnSuccess == true)
        assert(NeuroID.registeredUserID == expectedValue)

        assertStoredEventTypeAndCount(type: "LOG", count: 0)
        assert(NeuroID.datastore.queuedEvents.count == 0)

        NeuroID.registeredUserID = ""
    }

    func test_setRegisteredUserID_same_value() {
        NeuroID._isSDKStarted = true
        clearOutDataStore()

        let expectedValue = "test_ruid"

        NeuroID.registeredUserID = expectedValue

        let fnSuccess = identifierService.setRegisteredUserID(expectedValue)
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)

        assert(fnSuccess == true)
        assert(NeuroID.registeredUserID == expectedValue)

        assertStoredEventTypeAndCount(type: "SET_REGISTERED_USER_ID", count: 0)

        NeuroID.registeredUserID = ""
    }

}
