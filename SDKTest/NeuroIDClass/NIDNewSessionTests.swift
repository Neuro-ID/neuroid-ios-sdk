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

        NeuroIDCore.shared.configService = MockConfigService()
        let configuration = NeuroID.Configuration(clientKey: clientKey, isAdvancedDevice: false)
        _ = NeuroID.configure(configuration)
        NeuroIDCore._isTesting = true

        clearOutDataStore()
    }

    override func tearDown() {
        _ = NeuroID.stop()
        // Clear out the DataStore Events after each test
        clearOutDataStore()
        NeuroIDCore._isTesting = false
    }

    func assertSessionStartedTests(_ sessionRes: SessionStartResult) {
        assert(sessionRes.started)
        assert(NeuroIDCore.shared._isSDKStarted)

        assertStoredEventTypeAndCount(type: NIDEventName.createSession.rawValue, count: 1)
        assertStoredEventTypeAndCount(type: NIDEventName.mobileMetadataIOS.rawValue, count: 1)
        assertStoredEventTypeAndCount(type: NIDEventName.setUserId.rawValue, count: 1)
        assert(dataStore.queuedEvents.isEmpty)
    }

    func assertSessionNotStartedTests(_ sessionRes: SessionStartResult) {
        assert(!sessionRes.started)
        assert(sessionRes.sessionID == "")
        assert(!NeuroIDCore.shared._isSDKStarted)
    }

    func assertSetVariableEvents() {
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
    }

    //    clearSessionVariables
    func test_clearSessionVariables() {
        NeuroIDCore.shared.identifierService.sessionID = "myUserID"
        NeuroIDCore.shared.identifierService.registeredUserID = "myRegisteredUserID"
        NeuroIDCore.shared.linkedSiteID = "mySite"

        NeuroIDCore.shared.clearSessionVariables()

        assert(NeuroIDCore.shared.sessionID == nil)
        assert(NeuroIDCore.shared.registeredUserID == "")
        assert(NeuroIDCore.shared.linkedSiteID == nil)
    }

    func test_startSession_success_id() {
        NeuroIDCore.shared.identifierService.sessionID = nil
        NeuroIDCore.shared._isSDKStarted = false

        let expectedValue = "mySessionID"
        NeuroID.startSession(expectedValue) { sessionRes in
            self.assertSessionStartedTests(sessionRes)
            assert(expectedValue == sessionRes.sessionID)
        }

        assertSetVariableEvents()
        assertStoredEventTypeAndCount(type: "LOG", count: 3)
    }

    func test_startSession_success_no_id() {
        NeuroIDCore.shared.identifierService.sessionID = nil
        NeuroIDCore.shared._isSDKStarted = false

        let expectedValue = "mySessionID"
        NeuroID.startSession { sessionRes in
            self.assertSessionStartedTests(sessionRes)
            assert(expectedValue != sessionRes.sessionID)
        }

        assertSetVariableEvents()
    }

    func test_startSession_success_no_id_sdk_started() {
        NeuroIDCore.shared.identifierService.sessionID = nil
        NeuroIDCore.shared._isSDKStarted = true

        let expectedValue = "mySessionID"
        NeuroID.startSession { sessionRes in
            self.assertSessionStartedTests(sessionRes)
            assert(expectedValue != sessionRes.sessionID)
        }

        assertSetVariableEvents()
    }

    func test_startSession_success_id_sdk_started() {
        NeuroIDCore.shared.identifierService.sessionID = nil
        NeuroIDCore.shared._isSDKStarted = true

        let expectedValue = "mySessionID"
        NeuroID.startSession(expectedValue) { sessionRes in
            self.assertSessionStartedTests(sessionRes)
            assert(expectedValue == sessionRes.sessionID)
        }
        assertSetVariableEvents()
    }

    func test_startSession_failure_clientKey() {
        NeuroIDCore.shared.clientKey = nil

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
        NeuroIDCore.shared._isSDKStarted = true

        NeuroID.pauseCollection()

        assert(!NeuroIDCore.shared._isSDKStarted)
    }

    func test_resumeCollection() {
        NeuroIDCore.shared._isSDKStarted = false
        NeuroIDCore.shared.identifierService.sessionID = "temp"

        NeuroID.resumeCollection()

        assert(NeuroIDCore.shared._isSDKStarted)
    }

    func test_willNotResumeCollectionIfNotStarted() {
        NeuroIDCore.shared._isSDKStarted = false
        NeuroIDCore.shared.identifierService.sessionID = nil
        NeuroID.resumeCollection()

        assert(!NeuroIDCore.shared._isSDKStarted)
    }

    func test_stopSession() {
        let stopped = NeuroID.stopSession()

        assert(stopped)
    }

    func test_startAppFlow_valid_site() {
        let mySite = "form_thing123"
        NeuroIDCore.shared._isSDKStarted = true
        NeuroIDCore.shared.linkedSiteID = nil

        NeuroID.startAppFlow(siteID: mySite) { started in
            assert(started.started)
            assert(NeuroIDCore.shared.linkedSiteID == mySite)

            NeuroIDCore.shared._isSDKStarted = false
            NeuroIDCore.shared.linkedSiteID = nil
        }
    }

    func test_startAppFlow_invalid_site() {
        let mySite = "mySite"
        NeuroIDCore.shared._isSDKStarted = true
        NeuroIDCore.shared.linkedSiteID = nil

        NeuroID.startAppFlow(siteID: mySite) { started in
            assert(!started.started)
            assert(NeuroIDCore.shared.linkedSiteID == nil)

            NeuroIDCore.shared._isSDKStarted = false
        }
    }

    func test_clearSendOldFlowEvents_not_sampled() {
        dataStore.events.append(NIDEvent(rawType: "test"))
        NeuroIDCore.shared.configService = MockConfigService()

        NeuroIDCore.shared.clearSendOldFlowEvents {
            assert(self.dataStore.events.count == 0)

            NeuroIDCore.shared._isSDKStarted = false
        }
    }

    func test_clearSendOldFlowEvents_sampled() {
        dataStore.events.append(NIDEvent(rawType: "test"))
        NeuroIDCore.shared.configService = MockConfigService()

        let mockNetwork = MockNetworkService()
        NeuroIDCore.shared.networkService = mockNetwork

        NeuroIDCore.shared._isSDKStarted = true

        NeuroIDCore.shared.clearSendOldFlowEvents {
            assert(self.dataStore.events.count == 0)

            NeuroIDCore.shared._isSDKStarted = false
        }
    }
}
