//
//  NIDUserTests.swift
//  NeuroID
//

import XCTest

@testable import NeuroID

class NIDUserTests: XCTestCase {
    var state: StateStore = StateStore()
    var mockIdentifierService = MockIdentifierService()
    var mockEventStorageService = MockEventStorageService()
    var neuroID = NeuroIDCore()

    override func setUp() {
        state = StateStore()
        mockIdentifierService = MockIdentifierService()
        mockEventStorageService = MockEventStorageService()
        neuroID = NeuroIDCore(
            state: state,
            eventStorageService: mockEventStorageService,
            identifierService: mockIdentifierService
        )
    }

    override func tearDown() {
        mockIdentifierService.clearMocks()
    }

    // Identity ID

    func test_identify_success() {
        // Use real identifier service
        neuroID = NeuroIDCore(
            state: state,
            eventStorageService: mockEventStorageService
        )

        let response = neuroID.identify("abcd123")
        assert(response)
    }

    func test_identify_failure() {
        // Use real identifier service
        neuroID = NeuroIDCore(
            state: state,
            eventStorageService: mockEventStorageService
        )

        let response = neuroID.identify("")
        assert(!response)
    }

    // getIdentityId
    func test_getIdentityId_exists() {
        let expectedValue = "test_uid"
        state.setIdentityId(expectedValue)

        let value = neuroID.getIdentityId()

        assert(value == expectedValue)
    }

    func test_getIdentityId_not_exists() {
        state.setIdentityId(nil)
        let value = neuroID.getIdentityId()

        assert(value == "")
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
