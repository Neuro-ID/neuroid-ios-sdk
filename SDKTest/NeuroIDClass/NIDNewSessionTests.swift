//
//  NIDNewSessionTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//

@testable import NeuroID
import XCTest

class NIDNewSessionTests: BaseTestClass {
    override func setUpWithError() throws {
        // skip all tests in this class, remove this line to re-enabled tests
//        throw XCTSkip("Skipping all tests in this class.")

        NeuroID.shared.configService = MockConfigService()
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
        NeuroID._isTesting = true

        clearOutDataStore()
    }

    override func tearDown() {
        _ = NeuroID.stop()
        // Clear out the DataStore Events after each test
        clearOutDataStore()
        NeuroID._isTesting = false
    }

    func assertSessionStartedTests(_ sessionRes: SessionStartResult) {
        assert(sessionRes.started)
        assert(NeuroID.shared._isSDKStarted)

        assertStoredEventTypeAndCount(type: NIDEventName.createSession.rawValue, count: 1)
        assertStoredEventTypeAndCount(type: NIDEventName.mobileMetadataIOS.rawValue, count: 1)
        assertStoredEventTypeAndCount(type: NIDEventName.setUserId.rawValue, count: 1)
        assert(dataStore.queuedEvents.isEmpty)
    }

    func assertSessionNotStartedTests(_ sessionRes: SessionStartResult) {
        assert(!sessionRes.started)
        assert(sessionRes.sessionID == "")
        assert(!NeuroID.shared._isSDKStarted)
    }

    func assertSetVariableEvents() {
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
    }

    //    clearSessionVariables
    func test_clearSessionVariables() {
        NeuroID.shared.identifierService.sessionID = "myUserID"
        NeuroID.shared.identifierService.registeredUserID = "myRegisteredUserID"
        NeuroID.shared.linkedSiteID = "mySite"

        NeuroID.shared.clearSessionVariables()

        assert(NeuroID.shared.sessionID == nil)
        assert(NeuroID.shared.registeredUserID == "")
        assert(NeuroID.shared.linkedSiteID == nil)
    }

    func test_startSession_success_id() {
        NeuroID.shared.identifierService.sessionID = nil
        NeuroID.shared._isSDKStarted = false

        let expectedValue = "mySessionID"
        NeuroID.startSession(expectedValue) { sessionRes in
            self.assertSessionStartedTests(sessionRes)
            assert(expectedValue == sessionRes.sessionID)
        }

        assertSetVariableEvents()
        assertStoredEventTypeAndCount(type: "LOG", count: 3)
    }

    func test_startSession_success_no_id() {
        NeuroID.shared.identifierService.sessionID = nil
        NeuroID.shared._isSDKStarted = false

        let expectedValue = "mySessionID"
        NeuroID.startSession { sessionRes in
            self.assertSessionStartedTests(sessionRes)
            assert(expectedValue != sessionRes.sessionID)
        }

        assertSetVariableEvents()
    }

    func test_startSession_success_no_id_sdk_started() {
        NeuroID.shared.identifierService.sessionID = nil
        NeuroID.shared._isSDKStarted = true

        let expectedValue = "mySessionID"
        NeuroID.startSession { sessionRes in
            self.assertSessionStartedTests(sessionRes)
            assert(expectedValue != sessionRes.sessionID)
        }

        assertSetVariableEvents()
    }

    func test_startSession_success_id_sdk_started() {
        NeuroID.shared.identifierService.sessionID = nil
        NeuroID.shared._isSDKStarted = true

        let expectedValue = "mySessionID"
        NeuroID.startSession(expectedValue) { sessionRes in
            self.assertSessionStartedTests(sessionRes)
            assert(expectedValue == sessionRes.sessionID)
        }
        assertSetVariableEvents()
    }

    func test_startSession_failure_clientKey() {
        NeuroID.shared.clientKey = nil

        NeuroID.startSession { sessionRes in
            self.assertSessionNotStartedTests(sessionRes)
        }
    }

    func test_startSession_failure_userID() {
        NeuroID.startSession("MY bad -.-. id") {
            sessionRes in
            self.assertSessionNotStartedTests(sessionRes)
        }
        assertQueuedEventTypeAndCount(type: "SET_USER_ID", count: 0, skipType: true)
        assertQueuedEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(
            type: "SET_VARIABLE",
            origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue,
            originCode: SessionOrigin.NID_ORIGIN_CODE_FAIL.rawValue,
            queued: true
        )
        assertQueuedEventTypeAndCount(type: "LOG", count: 3)
    }

    func test_pauseCollection() {
        NeuroID.shared._isSDKStarted = true

        NeuroID.pauseCollection()

        assert(!NeuroID.shared._isSDKStarted)
    }

    func test_resumeCollection() {
        NeuroID.shared._isSDKStarted = false
        NeuroID.shared.identifierService.sessionID = "temp"

        NeuroID.resumeCollection()

        assert(NeuroID.shared._isSDKStarted)
    }

    func test_willNotResumeCollectionIfNotStarted() {
        NeuroID.shared._isSDKStarted = false
        NeuroID.shared.identifierService.sessionID = nil
        NeuroID.resumeCollection()

        assert(!NeuroID.shared._isSDKStarted)
    }

    func test_stopSession() {
        let stopped = NeuroID.stopSession()

        assert(stopped)
    }

    func test_startAppFlow_valid_site() {
        let mySite = "form_thing123"
        NeuroID.shared._isSDKStarted = true
        NeuroID.shared.linkedSiteID = nil

        NeuroID.startAppFlow(siteID: mySite) { started in
            assert(started.started)
            assert(NeuroID.shared.linkedSiteID == mySite)

            NeuroID.shared._isSDKStarted = false
            NeuroID.shared.linkedSiteID = nil
        }
    }

    func test_startAppFlow_invalid_site() {
        let mySite = "mySite"
        NeuroID.shared._isSDKStarted = true
        NeuroID.shared.linkedSiteID = nil

        NeuroID.startAppFlow(siteID: mySite) { started in
            assert(!started.started)
            assert(NeuroID.shared.linkedSiteID == nil)

            NeuroID.shared._isSDKStarted = false
        }
    }

    func test_clearSendOldFlowEvents_not_sampled() {
        dataStore.events.append(NIDEvent(rawType: "test"))
        NeuroID.shared.configService = MockConfigService()

        NeuroID.shared.clearSendOldFlowEvents {
            assert(self.dataStore.events.count == 0)

            NeuroID.shared._isSDKStarted = false
        }
    }

    func test_clearSendOldFlowEvents_sampled() {
        dataStore.events.append(NIDEvent(rawType: "test"))
        NeuroID.shared.configService = MockConfigService()

        let mockNetwork = MockNetworkService()
        NeuroID.shared.networkService = mockNetwork

        NeuroID.shared._isSDKStarted = true

        NeuroID.shared.clearSendOldFlowEvents {
            assert(self.dataStore.events.count == 0)

            NeuroID.shared._isSDKStarted = false
        }
    }
}
