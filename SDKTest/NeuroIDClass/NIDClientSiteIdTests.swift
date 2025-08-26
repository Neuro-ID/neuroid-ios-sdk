//
//  NIDClientSiteIdTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//

@testable import NeuroID
import XCTest

class NIDClientSiteIdTests: BaseTestClass {
    var neuroID = NeuroID()

    override func setUp() {
        neuroID = NeuroID()
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

    func test_getClientID() {
        UserDefaults.standard.setValue("test-cid", forKey: clientIdKey)
        NeuroID.shared.clientID = nil
        let value = NeuroID.getClientID()

        assert(value == "test-cid")
    }

    func test_getClientId_existing() {
        let expectedValue = "test-cid"

        NeuroID.shared.clientID = expectedValue
        UserDefaults.standard.set(expectedValue, forKey: clientIdKey)

        let value = NeuroID.getClientID()

        assert(value == expectedValue)
    }

    func test_getClientId_random() {
        let expectedValue = "test_cid"

        UserDefaults.standard.set(expectedValue, forKey: clientIdKey)

        let value = NeuroID.getClientID()

        assert(value != expectedValue)
        // ENG-8455 nid prefix should only exist for session id
        assert(value.prefix(3) != "nid")
    }

    func test_getClientKey() {
        NeuroID.shared.clientKey = nil
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
        let expectedValue = clientKey

        let value = NeuroID.shared.getClientKey()

        assert(value == expectedValue)
    }

    func test_getClientKeyFromLocalStorage() {
        let expectedValue = "testClientKey"

        UserDefaults.standard.setValue(expectedValue, forKey: clientKeyKey)

        let value = NeuroID.shared.getClientKeyFromLocalStorage()
        assert(value == expectedValue)
    }

    func test_setSiteId() {
        NeuroID.setSiteId(siteId: "test_site")

        assert(NeuroID.shared.siteID == "test_site")
    }
}
