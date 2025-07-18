//
//  NIDClientSiteIdTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//

@testable import NeuroID
import XCTest

class NIDClientSiteIdTests: BaseTestClass {
    func test_getClientID() {
        UserDefaults.standard.setValue("test-cid", forKey: clientIdKey)
        NeuroID.clientID = nil
        let value = NeuroID.getClientID()

        assert(value == "test-cid")
    }

    func test_getClientId_existing() {
        let expectedValue = "test-cid"

        NeuroID.clientID = expectedValue
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
        NeuroID.clientKey = nil
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
        let expectedValue = clientKey

        let value = NeuroID.getClientKey()

        assert(value == expectedValue)
    }

    func test_getClientKeyFromLocalStorage() {
        let expectedValue = "testClientKey"

        UserDefaults.standard.setValue(expectedValue, forKey: clientKeyKey)

        let value = NeuroID.getClientKeyFromLocalStorage()
        assert(value == expectedValue)
    }

    func test_setSiteId() {
        NeuroID.setSiteId(siteId: "test_site")

        assert(NeuroID.siteID == "test_site")
    }
}
