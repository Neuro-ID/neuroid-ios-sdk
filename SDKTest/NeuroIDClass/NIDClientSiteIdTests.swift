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
