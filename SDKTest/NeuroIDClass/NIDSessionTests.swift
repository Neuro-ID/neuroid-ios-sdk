//
//  NIDSessionTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//

@testable import NeuroID
import XCTest

class NIDSessionTests: BaseTestClass {
    override func setUpWithError() throws {
        let configuration = NeuroID.Configuration(clientKey: clientKey, isAdvancedDevice: false)
        _ = NeuroID.configure(configuration)
    }

    override func setUp() {
        NeuroIDCore.shared._isSDKStarted = true
        NeuroIDCore._isTesting = true
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
        NeuroIDCore._isTesting = false
    }

    func test_getSessionID() {
        let expectedValue = ""
        NeuroIDCore.shared.identifierService.sessionID = expectedValue

        let value = NeuroID.getSessionID()

        assert(value == expectedValue)
    }

    func test_getSessionID_existing() {
        let expectedValue = "test_sid"
        NeuroIDCore.shared.identifierService.sessionID = expectedValue

        let value = NeuroID.getSessionID()

        assert(value == expectedValue)
    }

    func test_createSession() {
        clearOutDataStore()
        NeuroIDCore.shared.datastore.removeSentEvents()

        NeuroIDCore.shared.createSession()

        assertStoredEventTypeAndCount(type: "CREATE_SESSION", count: 1)
        assertStoredEventTypeAndCount(type: "MOBILE_METADATA_IOS", count: 1)
    }

    func test_closeSession() {
        clearOutDataStore()
        do {
            let closeSession = try NeuroIDCore.shared.closeSession()
            assert(closeSession.ct == "SDK_EVENT")
        } catch {
            NIDLog.error("Threw on Close Session that shouldn't")
            XCTFail()
        }

        //        assertStoredEventTypeAndCount(type: "CLOSE_SESSION", count: 1)
    }

    func test_closeSession_whenStopped() {
        _ = NeuroID.stop()
        clearOutDataStore()

        XCTAssertThrowsError(
            try NeuroIDCore.shared.closeSession(),
            "Close Session throws an error when SDK is already stopped"
        )
    }

    func test_captureMobileMetadata() {
        clearOutDataStore()

        NeuroIDCore.shared.captureMobileMetadata()

        assertStoredEventTypeAndCount(type: NIDEventName.mobileMetadataIOS.rawValue, count: 1)
    }
}
