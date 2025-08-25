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
    var mockEventStorageService = MockEventStorageService()
    var identifierService = IdentifierService(
        logger: NIDLog(),
        validationService: ValidationService(logger: NIDLog()),
        eventStorageService: MockEventStorageService()
    )

    override func setUpWithError() throws {
        // skip all tests in this class, remove this line to re-enabled tests
    }

    override func setUp() {
        mockEventStorageService = MockEventStorageService()
        identifierService = IdentifierService(
            logger: NIDLog(),
            validationService: ValidationService(logger: NIDLog()),
            eventStorageService: mockEventStorageService
        )
    }

    override func tearDown() {
        clearOutDataStore()
        NeuroID._isTesting = false
    }

    // setSessionID
    func test_setSessionID_started_customer_origin() {
        identifierService.sessionID = nil
        let expectedValue = "test_uid"
        let fnSuccess = identifierService.setSessionID(expectedValue, true)

        assert(fnSuccess)
        assert(identifierService.sessionID == expectedValue)
    }

    func test_setSessionID_started_nid_origin() {
        identifierService.sessionID = nil
        let expectedValue = "test_uid"

        let fnSuccess = identifierService.setSessionID(expectedValue, false)

        assert(fnSuccess)
        assert(identifierService.sessionID == expectedValue)
    }

    // setRegisteredUserID
    func test_setRegisteredUserID_valid_not_set() {
        let expectedValue = "test_ruid"
        identifierService.registeredUserID = ""

        let fnSuccess = identifierService.setRegisteredUserID(expectedValue)

        assert(fnSuccess == true)
        assert(identifierService.registeredUserID == expectedValue)
    }

    func test_setRegisteredUserID_valid_already_set() {
        let expectedValue = "test_ruid"
        identifierService.registeredUserID = "setID"

        let fnSuccess = identifierService.setRegisteredUserID(expectedValue)

        assert(fnSuccess == true)
        assert(identifierService.registeredUserID == expectedValue)

        let warnLogMessages = mockEventStorageService.mockEventStore.filter {
            $0.type == NIDEventName.log.rawValue && $0.level == "WARN"
        }
        assert(warnLogMessages.count == 1)
    }

    func test_setRegisteredUserID_valid_same_value() {
        let expectedValue = "test_ruid"
        identifierService.registeredUserID = expectedValue

        let fnSuccess = identifierService.setRegisteredUserID(expectedValue)

        assert(fnSuccess == true)
        assert(identifierService.registeredUserID == expectedValue)

        let warnLogMessages = mockEventStorageService.mockEventStore.filter {
            $0.type == NIDEventName.log.rawValue && $0.level == "WARN"
        }
        assert(warnLogMessages.count == 0)
    }

    // setGenericIdentifier
    func test_setGenericIdentifier_valid_sessionID_duplicatesAllowed() {
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

        let userIDEvents = assertStoredEventTypeAndCount(
            dataStoreEvents: mockEventStorageService.mockEventStore,
            type: NIDEventName.setUserId.rawValue,
            count: 1
        )
        assert(userIDEvents[0].uid == expectedValue)
    }

    func test_setGenericIdentifier_valid_sessionID_duplicatesNotAllowed() {
        var successful = false
        let expectedValue = "myTestUserID"

        let result = identifierService.setGenericIdentifier(
            identifier: expectedValue,
            type: .sessionID,
            userGenerated: true,
            duplicatesAllowedCheck: { _ in false },
            validIDFunction: { successful = true }
        )

        assert(result == false)
        assert(successful == false)

        _ = assertStoredEventTypeAndCount(
            dataStoreEvents: mockEventStorageService.mockEventStore,
            type: NIDEventName.setUserId.rawValue,
            count: 0
        )
        assert(mockEventStorageService.mockEventStore.count == 1) // 1 for the scrub identifier fn
    }

    func test_setGenericIdentifier_invalid_sessionID_duplicatesAllowed() {
        let mockValidationService = MockValidationService()
        mockValidationService.validIdentifier = false
        identifierService = IdentifierService(
            logger: NIDLog(),
            validationService: mockValidationService,
            eventStorageService: mockEventStorageService
        )
        var successful = false
        let expectedValue = "myTestUserID"

        let result = identifierService.setGenericIdentifier(
            identifier: expectedValue,
            type: .sessionID,
            userGenerated: true,
            duplicatesAllowedCheck: { _ in true },
            validIDFunction: { successful = true }
        )

        assert(result == false)
        assert(successful == false)

        _ = assertStoredEventTypeAndCount(
            dataStoreEvents: mockEventStorageService.mockEventStore,
            type: NIDEventName.setUserId.rawValue,
            count: 0
        )

        let errorLogMessages = mockEventStorageService.mockEventStore.filter {
            $0.type == NIDEventName.log.rawValue && $0.level == "ERROR"
        }

        assert(errorLogMessages.count == 1)
    }

    func test_setGenericIdentifier_valid_registeredID_duplicatesAllowed() {
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

        _ = assertStoredEventTypeAndCount(
            dataStoreEvents: mockEventStorageService.mockEventStore,
            type: NIDEventName.setRegisteredUserId.rawValue,
            count: 1
        )
    }

    func test_setGenericIdentifier_valid_attemptedLogin_duplicatesAllowed() {
        var successful = false
        let expectedValue = "myTestUserID"
        let result = identifierService.setGenericIdentifier(
            identifier: expectedValue,
            type: .attemptedLogin,
            userGenerated: true,
            duplicatesAllowedCheck: { _ in true },
            validIDFunction: { successful = true }
        )

        assert(result == true)
        assert(successful == true)

        _ = assertStoredEventTypeAndCount(
            dataStoreEvents: mockEventStorageService.mockEventStore,
            type: NIDEventName.attemptedLogin.rawValue,
            count: 1
        )
    }

    // clearIDs
    func test_clearIDs() {
        identifierService.sessionID = "testSession"
        identifierService.registeredUserID = "testRegistered"

        identifierService.clearIDs()

        assert(identifierService.sessionID == nil)
        assert(identifierService.registeredUserID == "")
    }

    // logScrubbedIdentityAttempt
    func test_logScrubbedIdentityAttempt() {
        let id = "123-23-4568"
        let expectedId = "***-**-****"
        let scrubbedId = identifierService.logScrubbedIdentityAttempt(
            identifier: id,
            message: "Message Test"
        )
        XCTAssertEqual(scrubbedId, expectedId)
        _ = assertStoredEventTypeAndCount(
            dataStoreEvents: mockEventStorageService.mockEventStore,
            type: NIDEventName.log.rawValue,
            count: 1
        )
    }

    // scrubIdentifier
    func test_scrubIdentifier_scrubEmailId() {
        let id = "tt@test.com"
        let expectedId = "t*@test.com"
        let scrubbedId = identifierService.scrubIdentifier(id)
        XCTAssertEqual(scrubbedId, expectedId)
    }

    func test_scrubIdentifier_unScrubbedID() {
        let id = "123_testing123"
        let expectedId = "123_testing123"
        let unscrubbedId = identifierService.scrubIdentifier(id)
        XCTAssertEqual(unscrubbedId, expectedId)
    }

    func test_scrubIdentifier_scrubSSN() {
        let id = "123-23-4568"
        let expectedId = "***-**-****"
        let scrubbedId = identifierService.scrubIdentifier(id)
        XCTAssertEqual(scrubbedId, expectedId)
    }

    // sendOriginEvent
    func test_sendOriginEvent() {
        let testOrigin = SessionIDOriginalResult(
            origin: "origin", originCode: "originCode", idValue: "idValue",
            idType: .sessionID
        )

        identifierService.sendOriginEvent(testOrigin)

        let originEvents = assertStoredEventTypeAndCount(
            dataStoreEvents: mockEventStorageService.mockEventStore,
            type: NIDEventName.setVariable.rawValue,
            count: 4
        )

        assert(mockEventStorageService.saveEventToDataStoreCount == 4)

        assert(originEvents[0].key == "sessionIdCode")
        assert(originEvents[0].v == testOrigin.originCode)

        assert(originEvents[1].key == "sessionIdSource")
        assert(originEvents[1].v == testOrigin.origin)

        assert(originEvents[2].key == "sessionId")
        assert(originEvents[2].v == testOrigin.idValue)

        assert(originEvents[3].key == "sessionIdType")
        assert(originEvents[3].v == testOrigin.idType.rawValue)
    }

    func test_getOriginResult_valid_userGenerated() {
        let result = identifierService.getOriginResult(
            idValue: "idValue",
            validID: true,
            userGenerated: true,
            idType: .sessionID
        )

        assert(result.origin == SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue)
        assert(result.originCode == SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue)
    }

    func test_getOriginResult_valid_nidGenerated() {
        let result = identifierService.getOriginResult(
            idValue: "idValue",
            validID: true,
            userGenerated: false,
            idType: .sessionID
        )

        assert(result.origin == SessionOrigin.NID_ORIGIN_NID_SET.rawValue)
        assert(result.originCode == SessionOrigin.NID_ORIGIN_CODE_NID.rawValue)
    }

    func test_getOriginResult_invalid_nidGenerated() {
        let result = identifierService.getOriginResult(
            idValue: "idValue",
            validID: false,
            userGenerated: false,
            idType: .sessionID
        )

        assert(result.origin == SessionOrigin.NID_ORIGIN_NID_SET.rawValue)
        assert(result.originCode == SessionOrigin.NID_ORIGIN_CODE_FAIL.rawValue)
    }
}
