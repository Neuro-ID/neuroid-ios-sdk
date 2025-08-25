//
//  NIDUserTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//

@testable import NeuroID
import XCTest

class NIDUserTests: BaseTestClass {
    var mockIdentifierService = MockIdentifierService()
    var mockEventStorageService = MockEventStorageService()
    var neuroID = NeuroID()

    override func setUp() {
        mockIdentifierService = MockIdentifierService()
        mockEventStorageService = MockEventStorageService()
        neuroID = NeuroID(
            eventStorageService: mockEventStorageService,
            identifierService: mockIdentifierService
        )
    }

    override func tearDown() {
        mockIdentifierService.clearMocks()
    }

    // identify
    func test_identify_success() {
        let expectedValue = true
        mockIdentifierService.setSessionIDResponse = expectedValue

        let response = neuroID.identify("")

        assert(response == expectedValue)
        assert(mockIdentifierService.setSessionIDCount == 1)
    }

    func test_identify_failure() {
        let expectedValue = false
        mockIdentifierService.setSessionIDResponse = expectedValue

        let response = neuroID.identify("")

        assert(response == expectedValue)
        assert(mockIdentifierService.setSessionIDCount == 1)
    }

    // getSessionID
    func test_getSessionID_exists() {
        let expectedValue = "test_uid"
        mockIdentifierService.sessionID = expectedValue

        let value = neuroID.getSessionID()

        assert(value == expectedValue)
    }

    func test_getSessionID_not_exists() {
        let expectedValue = ""
        mockIdentifierService.sessionID = nil

        let value = neuroID.getSessionID()

        assert(value == expectedValue)
    }

    // setRegisteredUserID
    func test_setRegisteredUserID_success() {
        let expectedValue = true
        mockIdentifierService.setRegisteredIDResponse = expectedValue

        let response = neuroID.setRegisteredUserID("")

        assert(response == expectedValue)
        assert(mockIdentifierService.setRegisteredUserIDCount == 1)
    }

    func test_setRegisteredUserID_failure() {
        let expectedValue = false
        mockIdentifierService.setRegisteredIDResponse = expectedValue

        let response = neuroID.setRegisteredUserID("")

        assert(response == expectedValue)
        assert(mockIdentifierService.setRegisteredUserIDCount == 1)
    }

    // getRegisteredUserID
    func test_getRegisteredUserID_exists() {
        let expectedValue = "test_uid"
        mockIdentifierService.registeredUserID = expectedValue

        let value = neuroID.getRegisteredUserID()

        assert(value == expectedValue)
    }

    func test_getRegisteredUserID_not_exists() {
        let expectedValue = ""
        mockIdentifierService.registeredUserID = expectedValue

        let value = neuroID.getRegisteredUserID()

        assert(value == expectedValue)
    }

    // attemptedLogin
    func test_attemptedLogin_valid() {
        let expectedValue = true
        mockIdentifierService.setGenericIdentifierResponse = expectedValue

        let response = neuroID.attemptedLogin()

        assert(response == expectedValue)
        assert(mockIdentifierService.setGenericIdentifierCount == 1)
        assert(mockEventStorageService.saveEventToDataStoreCount == 0)
    }

    func test_attemptedLogin_invalid() {
        let expectedValue = true
        mockIdentifierService.setGenericIdentifierResponse = false

        let response = neuroID.attemptedLogin()

        assert(response == expectedValue)
        assert(mockIdentifierService.setGenericIdentifierCount == 1)
        assert(mockEventStorageService.saveEventToDataStoreCount == 1)
        assert(mockEventStorageService.mockEventStore[0].type == NIDEventName.attemptedLogin.rawValue)
        assert(mockEventStorageService.mockEventStore[0].uid == "scrubbed-id-failed-validation")
    }
}
