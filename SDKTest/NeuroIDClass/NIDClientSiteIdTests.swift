//
//  NIDClientSiteIdTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//

@testable import NeuroID
import XCTest

class NIDClientSiteIdTests: BaseTestClass {
    var mockEventStorageService = MockEventStorageService()
    var mockValidationService = MockValidationService()
    var mockConfigService = MockConfigService()
    var neuroID = NeuroID()

    override func setUp() {
        mockEventStorageService = MockEventStorageService()
        mockValidationService = MockValidationService()
        mockConfigService = MockConfigService()
        neuroID = NeuroID(
            eventStorageService: mockEventStorageService,
            validationService: mockValidationService,
            configService: mockConfigService
        )
    }

    // getClientID
    // user default does not exist and clientID is empty - generate new one
    func test_getClientID_no_ud_no_cid() {
        UserDefaults.standard.setValue(nil, forKey: clientIdKey)
        neuroID.clientID = nil

        let result = neuroID.getClientID()

        assert(result == neuroID.clientID)
    }

    // user default does not exist and clientID is not empty - use clientID
    func test_getClientID_no_ud_cid() {
        let expectedValue = "testID"
        UserDefaults.standard.setValue(nil, forKey: clientIdKey)
        neuroID.clientID = expectedValue

        let result = neuroID.getClientID()

        assert(result == expectedValue)
        assert(result == neuroID.clientID)
    }

    // user default exists and clientID is empty - use UD
    func test_getClientID_ud_no_cid() {
        let expectedValue = "testID"
        UserDefaults.standard.setValue(expectedValue, forKey: clientIdKey)
        neuroID.clientID = nil

        let result = neuroID.getClientID()

        assert(result == expectedValue)
        assert(result != neuroID.clientID)
        assert(neuroID.clientID == nil)
    }

    // UD exists and clientID is not empty - use clientID
    func test_getClientID_ud_cid() {
        let expectedValue = "testID"
        UserDefaults.standard.setValue("uid", forKey: clientIdKey)
        neuroID.clientID = expectedValue

        let result = neuroID.getClientID()

        assert(result == expectedValue)
        assert(result == neuroID.clientID)
    }

    // UD exists and clientID is empty BUT UD has _ - generate new one
    func test_getClientID_bad_ud_no_cid() {
        let expectedValue = "test_ID"
        UserDefaults.standard.setValue(expectedValue, forKey: clientIdKey)
        neuroID.clientID = nil

        let result = neuroID.getClientID()

        assert(result != expectedValue)
        assert(result == neuroID.clientID)
    }

    // UD not exist and clientID is not empty BUT has _ - generate new one
    func test_getClientID_no_ud_bad_cid() {
        let expectedValue = "test_ID"
        UserDefaults.standard.setValue(nil, forKey: clientIdKey)
        neuroID.clientID = expectedValue

        let result = neuroID.getClientID()

        assert(result != expectedValue)
        assert(result == neuroID.clientID)
    }

    // setSiteId - DEPRECATED
    func test_setSiteId() {
        neuroID.siteID = ""
        neuroID.setSiteId(siteId: "test_site")

        assert(neuroID.siteID == "test_site")
    }

    // getClientKeyFromLocalStorage
    func test_getClientKeyFromLocalStorage_existing() {
        let expectedValue = "testClientKey"

        UserDefaults.standard.setValue(expectedValue, forKey: clientKeyKey)

        let value = neuroID.getClientKeyFromLocalStorage()
        assert(value == expectedValue)
    }

    func test_getClientKeyFromLocalStorage_nil() {
        let expectedValue: String? = nil

        UserDefaults.standard.setValue(expectedValue, forKey: clientKeyKey)

        let value = neuroID.getClientKeyFromLocalStorage()
        assert(value != expectedValue)
        assert(value == "")
    }

    // getClientKey
    func test_getClientKey_nil() {
        neuroID.clientKey = nil
        let expectedValue = ""

        let value = neuroID.getClientKey()

        assert(value == expectedValue)
        assert(neuroID.clientKey == nil)
    }

    func test_getClientKey_existing() {
        let expectedValue = "existing"
        neuroID.clientKey = expectedValue

        let value = neuroID.getClientKey()

        assert(value == expectedValue)
        assert(neuroID.clientKey == expectedValue)
    }

    // addLinkedSiteID
    func test_addLinkedSiteID_invalid_siteID() {
        mockValidationService.validSiteID = false
        neuroID.linkedSiteID = nil

        neuroID.addLinkedSiteID("invalidID")

        assert(neuroID.linkedSiteID == nil)
        assert(mockEventStorageService.mockEventStore.isEmpty)
    }

    func test_addLinkedSiteID_valid_siteID() {
        mockValidationService.validSiteID = true
        neuroID.linkedSiteID = nil

        let expectedValue = "validID"

        neuroID.addLinkedSiteID(expectedValue)

        assert(neuroID.linkedSiteID == expectedValue)
        assert(mockEventStorageService.mockEventStore.count == 1)
        let linkedSiteEvents = assertStoredEventTypeAndCount(
            dataStoreEvents: mockEventStorageService.mockEventStore,
            type: NIDEventName.setLinkedSite.rawValue,
            count: 1
        )

        assert(linkedSiteEvents[0].v == expectedValue)
    }
}
