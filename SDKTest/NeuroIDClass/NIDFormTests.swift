//
//  NIDFormTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//
@testable import NeuroID
import XCTest

class NIDFormTests: BaseTestClass {
    override func setUpWithError() throws {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
    }

    override func setUp() {
        NeuroID.shared._isSDKStarted = true
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    func test_formSubmit() {
        clearOutDataStore()
        let _ = NeuroID.formSubmit()

        assertStoredEventTypeAndCount(type: "APPLICATION_SUBMIT", count: 1)
    }

    func test_formSubmitFailure() {
        clearOutDataStore()
        let _ = NeuroID.formSubmitFailure()

        assertStoredEventTypeAndCount(type: "APPLICATION_SUBMIT_FAILURE", count: 1)
    }

    func test_formSubmitSuccess() {
        clearOutDataStore()
        let _ = NeuroID.formSubmitSuccess()

        assertStoredEventTypeAndCount(type: "APPLICATION_SUBMIT_SUCCESS", count: 1)
    }
}
