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

        NeuroID.configService = MockConfigService()
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
        assert(NeuroID._isSDKStarted)
        assert(NeuroID.sendCollectionWorkItem == nil) // In real world it would != nil but because of tests we don't want to trigger a re-occuring event

        assertStoredEventTypeAndCount(type: NIDSessionEventName.createSession.rawValue, count: 1)
        assertStoredEventTypeAndCount(type: NIDSessionEventName.mobileMetadataIOS.rawValue, count: 1)
        assertStoredEventTypeAndCount(type: NIDSessionEventName.setUserId.rawValue, count: 1)
        assert(NeuroID.datastore.queuedEvents.isEmpty)
    }

    func assertSessionNotStartedTests(_ sessionRes: SessionStartResult) {
        assert(!sessionRes.started)
        assert(sessionRes.sessionID == "")
        assert(!NeuroID._isSDKStarted)
        assert(NeuroID.sendCollectionWorkItem == nil) // In real world it would != nil but because of tests we don't want to trigger a re-occuring event
    }

    func assertSetVariableEvents() {
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
    }

    //    clearSessionVariables
    func test_clearSessionVariables() {
        NeuroID.sessionID = "myUserID"
        NeuroID.registeredUserID = "myRegisteredUserID"
        NeuroID.linkedSiteID = "mySite"

        NeuroID.clearSessionVariables()

        assert(NeuroID.sessionID == nil)
        assert(NeuroID.registeredUserID == "")
        assert(NeuroID.linkedSiteID == nil)
    }

    func test_startSession_success_id() {
        NeuroID.sessionID = nil
        NeuroID._isSDKStarted = false

        let expectedValue = "mySessionID"
        NeuroID.startSession(expectedValue) { sessionRes in
            self.assertSessionStartedTests(sessionRes)
            assert(expectedValue == sessionRes.sessionID)
        }

        assertSetVariableEvents()
        assertStoredEventTypeAndCount(type: "LOG", count: 3)
    }

    func test_startSession_success_no_id() {
        NeuroID.sessionID = nil
        NeuroID._isSDKStarted = false

        let expectedValue = "mySessionID"
        NeuroID.startSession { sessionRes in
            self.assertSessionStartedTests(sessionRes)
            assert(expectedValue != sessionRes.sessionID)
        }

        assertSetVariableEvents()
    }

    func test_startSession_success_no_id_sdk_started() {
        NeuroID.sessionID = nil
        NeuroID._isSDKStarted = true

        let expectedValue = "mySessionID"
        NeuroID.startSession { sessionRes in
            self.assertSessionStartedTests(sessionRes)
            assert(expectedValue != sessionRes.sessionID)
        }

        assertSetVariableEvents()
    }

    func test_startSession_success_id_sdk_started() {
        NeuroID.sessionID = nil
        NeuroID._isSDKStarted = true

        let expectedValue = "mySessionID"
        NeuroID.startSession(expectedValue) { sessionRes in
            self.assertSessionStartedTests(sessionRes)
            assert(expectedValue == sessionRes.sessionID)
        }
        assertSetVariableEvents()
    }

    func test_startSession_failure_clientKey() {
        NeuroID.clientKey = nil
        NeuroID.sendCollectionWorkItem = nil

        NeuroID.startSession { sessionRes in
            self.assertSessionNotStartedTests(sessionRes)
        }
    }

    func test_startSession_failure_userID() {
        NeuroID.sendCollectionWorkItem = nil
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
        NeuroID._isSDKStarted = true
        NeuroID.sendCollectionWorkItem = DispatchWorkItem {}

        NeuroID.pauseCollection()

        assert(!NeuroID._isSDKStarted)
        assert(NeuroID.sendCollectionWorkItem == nil)
    }

    func test_resumeCollection() {
        NeuroID._isSDKStarted = false
        NeuroID.identifierService.sessionID = "temp"
        NeuroID.sendCollectionWorkItem = nil

        NeuroID.resumeCollection()

        assert(NeuroID._isSDKStarted)
        assert(NeuroID.sendCollectionWorkItem != nil)
    }

    func test_willNotResumeCollectionIfNotStarted() {
        NeuroID._isSDKStarted = false
        NeuroID.identifierService.sessionID = nil
        NeuroID.resumeCollection()

        assert(!NeuroID._isSDKStarted)
    }

    func test_stopSession() {
        let stopped = NeuroID.stopSession()

        assert(stopped)
    }

    func test_startAppFlow_valid_site() {
        let mySite = "form_thing123"
        NeuroID._isSDKStarted = true
        NeuroID.linkedSiteID = nil

        NeuroID.startAppFlow(siteID: mySite) { started in
            assert(started.started)
            assert(NeuroID.linkedSiteID == mySite)

            NeuroID._isSDKStarted = false
            NeuroID.linkedSiteID = nil
        }
    }

    func test_startAppFlow_invalid_site() {
        let mySite = "mySite"
        NeuroID._isSDKStarted = true
        NeuroID.linkedSiteID = nil

        NeuroID.startAppFlow(siteID: mySite) { started in
            assert(!started.started)
            assert(NeuroID.linkedSiteID == nil)

            NeuroID._isSDKStarted = false
        }
    }

    func test_clearSendOldFlowEvents_not_sampled() {
        NeuroID.datastore.events.append(NIDEvent(rawType: "test"))
        NeuroID.configService = MockConfigService()

        NeuroID.clearSendOldFlowEvents {
            assert(NeuroID.datastore.events.count == 0)

            NeuroID._isSDKStarted = false
        }
    }

    func test_clearSendOldFlowEvents_sampled() {
        NeuroID.datastore.events.append(NIDEvent(rawType: "test"))
        NeuroID.configService = MockConfigService()

        let mockNetwork = NIDNetworkServiceTestImpl()
        NeuroID.networkService = mockNetwork

        NeuroID._isSDKStarted = true

        NeuroID.clearSendOldFlowEvents {
            assert(NeuroID.datastore.events.count == 0)

            NeuroID._isSDKStarted = false
        }
    }
}
