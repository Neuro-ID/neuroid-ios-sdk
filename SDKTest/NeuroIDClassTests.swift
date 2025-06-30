//
//  NeuroIDClassTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 4/5/23.
//

@testable import NeuroID
import XCTest

class NeuroIDClassTests: BaseTestClass {
    let mockService = MockDeviceSignalService()
    
    override func setUpWithError() throws {
        // skip all tests in this class, remove this line to re-enabled tests
        throw XCTSkip("Skipping all tests in this class.")
        // _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
    }

    override func setUp() {
        UserDefaults.standard.removeObject(forKey: Constants.storageAdvancedDeviceKey.rawValue)
        mockService.mockResult = .success(("mock", Double(Int.random(in: 0 ..< 3000))))
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    func test_getAdvDeviceLatency() {
        let mockService = MockDeviceSignalService()
        NeuroID.deviceSignalService = mockService
        _ = NeuroID.configure(clientKey: "key_test_0OMmplsawAp2CQfWrytWA3wL")
        let randomTimeInMilliseconds = Double(Int.random(in: 0 ..< 3000))
        mockService.mockResult = .success(("empty mock result. Can be filled with anything", randomTimeInMilliseconds))
        NeuroID.start(true) { _ in
            self.assertStoredEventCount(type: "ADVANCED_DEVICE_REQUEST", count: 0)
        }
    }

    func test_configure_success() {
        clearOutDataStore()
        // remove things configured in setup
        NeuroID.clientKey = nil
        UserDefaults.standard.setValue(nil, forKey: clientKeyKey)
        UserDefaults.standard.setValue("testTabId", forKey: tabIdKey)

        let configured = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
        assert(configured)

        let clientKeyValue = UserDefaults.standard.string(forKey: clientKeyKey)
        assert(clientKeyValue == clientKey)

        let tabIdValue = UserDefaults.standard.string(forKey: tabIdKey)
        assert(tabIdValue == nil)

        assertStoredEventCount(type: "CREATE_SESSION", count: 0)

        assert(NeuroID.environment == "\(Constants.environmentLive.rawValue)")
    }

    func test_configure_invalidKey() {
        NeuroID.setDevTestingURL()
        clearOutDataStore()
        // remove things configured in setup
        NeuroID.environment = Constants.environmentTest.rawValue
        NeuroID.clientKey = nil
        UserDefaults.standard.setValue(nil, forKey: clientKeyKey)
        UserDefaults.standard.setValue("testTabId", forKey: tabIdKey)

        let configured = NeuroID.configure(clientKey: "invalid_key", isAdvancedDevice: false)
        assert(configured == false)

        let clientKeyValue = UserDefaults.standard.string(forKey: clientKeyKey)
        assert(clientKeyValue == nil)

        let tabIdValue = UserDefaults.standard.string(forKey: tabIdKey)
        assert(tabIdValue == "testTabId-invalid-client-key")

        assertStoredEventCount(type: "CREATE_SESSION", count: 0)

        // 1 Log event should be in queue if the key fails validation
        self.assertQueuedEventTypeAndCount(type: "LOG", count: 1)

        assert(NeuroID.environment == "\(Constants.environmentTest.rawValue)")
    }

    func test_start_failure() {
        tearDown()
        NeuroID._isSDKStarted = false
        NeuroID.clientKey = nil

        // pre tests
        assert(!NeuroID.isSDKStarted)
        assert(NeuroID.clientKey == nil)

        // action
        NeuroID.start { started in
            assert(!started)
            // post action test
            assert(!NeuroID.isSDKStarted)
        }
    }

    func test_start_success() {
        tearDown()
        NeuroID._isSDKStarted = false

        // pre tests
        assert(!NeuroID.isSDKStarted)

        // action
        NeuroID.start { started in
            // post action test
            assert(started)
            assert(NeuroID.isSDKStarted)
            assert(NeuroID.datastore.events.count >= 2)
            self.assertStoredEventCount(type: "CREATE_SESSION", count: 0)
            self.assertStoredEventCount(type: "MOBILE_METADATA_IOS", count: 0)
        }
    }

    func test_start_success_queuedEvent() {
        _ = NeuroID.stop()
        NeuroID._isSDKStarted = false

        // pre tests
        assert(!NeuroID.isSDKStarted)
        
        clearOutDataStore()

        // action
        NeuroID.start { started in
            // post action test
            assert(started)
            assert(NeuroID.isSDKStarted)
            assert(NeuroID.datastore.events.count == 2)

            self.assertStoredEventCount(type: "CREATE_SESSION", count: 0)
            self.assertStoredEventCount(type: "MOBILE_METADATA_IOS", count: 0)
            self.assertStoredEventCount(type: "APPLICATION_METADATA", count: 0)
            self.assertStoredEventCount(type: "LOG", count: 2)
        }
    }

    func test_stop() {
        NeuroID._isSDKStarted = true
        assert(NeuroID.isSDKStarted)

        let stopped = NeuroID.stop()
        assert(stopped)
        assert(!NeuroID.isSDKStarted)
    }

    func test_getSDKVersion() {
        let expectedValue = ParamsCreator.getSDKVersion()

        let value = NeuroID.getSDKVersion()

        assert(value == expectedValue)

        let resultAdvTrue = NeuroID.getSDKVersion()
        assert(resultAdvTrue.contains("-adv"))

        NeuroID.isRN = true
        let resultRNTrue = NeuroID.getSDKVersion()
        assert(resultRNTrue.contains("-rn"))

        NeuroID.isRN = false
        let resultRNFalse = NeuroID.getSDKVersion()
        assert(!resultRNFalse.contains("-rn"))
    }
}

class NIDRegistrationTests: BaseTestClass {

    override func setUpWithError() throws {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
    }

    override func setUp() {
        NeuroID._isSDKStarted = true
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }


    func test_excludeViewByTestID() {
        clearOutDataStore()
        NeuroID.excludedViewsTestIDs = []
        let expectedValue = "testScreenName"

        NeuroID.excludeViewByTestID(excludedView: expectedValue)

        let contains = NeuroID.excludedViewsTestIDs.contains(where: { $0 == expectedValue })
        assert(contains)

        assert(NeuroID.excludedViewsTestIDs.count == 1)
    }

    func test_manuallyRegisterTarget_valid_type() {
        clearOutDataStore()
        let uiView = UITextField()
        uiView.id = "wow"

        NeuroID.manuallyRegisterTarget(view: uiView)

        assertStoredEventTypeAndCount(type: "REGISTER_TARGET", count: 1)

        let allEvents = NeuroID.datastore.getAllEvents()
        let validEvents = allEvents.filter { $0.type == "REGISTER_TARGET" }
        assert(validEvents[0].tgs == "wow")
        assert(validEvents[0].et == "UITextField::UITextField")
    }

    func test_manuallyRegisterTarget_invalid_type() {
        clearOutDataStore()
        let uiView = UIView()

        NeuroID.manuallyRegisterTarget(view: uiView)

        assertDataStoreCount(count: 0)
    }

    func test_manuallyRegisterRNTarget() {
        clearOutDataStore()

        let event = NeuroID.manuallyRegisterRNTarget(
            id: "test",
            className: "testClassName",
            screenName: "testScreenName",
            placeHolder: "testPlaceholder"
        )

        assert(event.tgs == "test")
        assert(event.et == "testClassName")
        assert(event.etn == "INPUT")

        assertStoredEventTypeAndCount(type: "REGISTER_TARGET", count: 1)
    }

    func test_setCustomVariable() {
        clearOutDataStore()
        let event = NeuroID.setCustomVariable(key: "t", v: "v")

        usleep(500_000) // Sleep for 500ms (500,000 microseconds)
        
        XCTAssertTrue(event.type == NIDSessionEventName.setVariable.rawValue)
        XCTAssertTrue(event.key == "t")
        XCTAssertTrue(event.v == "v")
        
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 0)
    }

    func test_setVariable() {
        clearOutDataStore()
        let event = NeuroID.setVariable(key: "t", value: "v")
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)

        XCTAssertTrue(event.type == NIDSessionEventName.setVariable.rawValue)
        XCTAssertTrue(event.key == "t")
        XCTAssertTrue(event.v == "v")
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 0)
    }
}

class NIDSessionTests: BaseTestClass {
    override func setUpWithError() throws {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
    }

    override func setUp() {
        NeuroID._isSDKStarted = true
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }


    func test_getSessionID() {
        let expectedValue = ""
        NeuroID.sessionID = expectedValue

        let value = NeuroID.getSessionID()

        assert(value == expectedValue)
    }

    func test_getSessionID_existing() {
        let expectedValue = "test_sid"
        NeuroID.sessionID = expectedValue

        let value = NeuroID.getSessionID()

        assert(value == expectedValue)
    }

    func test_createSession() {
        clearOutDataStore()
        NeuroID.datastore.removeSentEvents()

        NeuroID.createSession()
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)

        assertStoredEventTypeAndCount(type: "CREATE_SESSION", count: 0)
        assertStoredEventTypeAndCount(type: "MOBILE_METADATA_IOS", count: 0)
    }

    func test_closeSession() {
        clearOutDataStore()
        do {
            let closeSession = try NeuroID.closeSession()
            assert(closeSession.ct == "SDK_EVENT")
        } catch {
            NIDLog.e("Threw on Close Session that shouldn't")
            XCTFail()
        }

        //        assertStoredEventTypeAndCount(type: "CLOSE_SESSION", count: 1)
    }

    func test_closeSession_whenStopped() {
        _ = NeuroID.stop()
        clearOutDataStore()

        XCTAssertThrowsError(
            try NeuroID.closeSession(),
            "Close Session throws an error when SDK is already stopped"
        )
    }

    func test_captureMobileMetadata() {
        clearOutDataStore()

        NeuroID.captureMobileMetadata()

        assertStoredEventTypeAndCount(type: NIDSessionEventName.mobileMetadataIOS.rawValue, count: 1)
    }
}

class NIDNewSessionTests: BaseTestClass {

    override func setUpWithError() throws {
        // skip all tests in this class, remove this line to re-enabled tests
        throw XCTSkip("Skipping all tests in this class.")
        //NeuroID.configService = MockConfigService()
        //_ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
    }

    override func tearDown() {
        _ = NeuroID.stop()
        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    func assertSessionStartedTests(_ sessionRes: SessionStartResult) {
        assert(sessionRes.started)
        assert(NeuroID._isSDKStarted)
        assert(NeuroID.sendCollectionWorkItem == nil) // In real world it would != nil but because of tests we don't want to trigger a re-occuring event

        assertStoredEventTypeAndCount(type: NIDSessionEventName.createSession.rawValue, count: 0)
        assertStoredEventTypeAndCount(type: NIDSessionEventName.mobileMetadataIOS.rawValue, count: 0)
        assertStoredEventTypeAndCount(type: NIDSessionEventName.setUserId.rawValue, count: 0)
        assert(NeuroID.datastore.queuedEvents.isEmpty)
    }

    func assertSessionNotStartedTests(_ sessionRes: SessionStartResult) {
        assert(!sessionRes.started)
        assert(sessionRes.sessionID == "")
        assert(!NeuroID._isSDKStarted)
        assert(NeuroID.sendCollectionWorkItem == nil) // In real world it would != nil but because of tests we don't want to trigger a re-occuring event
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
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)

        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 0)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 0)
        assertStoredEventTypeAndCount(type: "LOG", count: 1)
    }

    func test_startSession_success_no_id() {
        NeuroID.sessionID = nil
        NeuroID._isSDKStarted = false

        let expectedValue = "mySessionID"
        NeuroID.startSession { sessionRes in
            self.assertSessionStartedTests(sessionRes)
            assert(expectedValue != sessionRes.sessionID)
        }
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)

        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 0)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 0)
    }

    func test_startSession_success_no_id_sdk_started() {
        NeuroID.sessionID = nil
        NeuroID._isSDKStarted = true

        let expectedValue = "mySessionID"
        NeuroID.startSession { sessionRes in
            self.assertSessionStartedTests(sessionRes)
            assert(expectedValue != sessionRes.sessionID)
        }
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)
        
        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 0)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 0)
    }

    func test_startSession_success_id_sdk_started() {
        NeuroID.sessionID = nil
        NeuroID._isSDKStarted = true

        let expectedValue = "mySessionID"
        NeuroID.startSession(expectedValue) { sessionRes in
            self.assertSessionStartedTests(sessionRes)
            assert(expectedValue == sessionRes.sessionID)
        }
        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 0)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 0)
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
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_FAIL.rawValue, queued: true)
        assertQueuedEventTypeAndCount(type: "LOG", count: 5)
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
        NeuroID.sessionID = "temp"
        NeuroID.sendCollectionWorkItem = nil

        NeuroID.resumeCollection()

        assert(NeuroID._isSDKStarted)
        assert(NeuroID.sendCollectionWorkItem != nil)
    }

    func test_willNotResumeCollectionIfNotStarted() {
        NeuroID._isSDKStarted = false
        NeuroID.sessionID = nil
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
        let mockSampling = NIDSamplingService()
        mockSampling._isSessionFlowSampled = false
        NeuroID.samplingService = mockSampling

        NeuroID.clearSendOldFlowEvents {
            assert(NeuroID.datastore.events.count == 0)

            NeuroID._isSDKStarted = false
        }
    }

    func test_clearSendOldFlowEvents_sampled() {
        NeuroID.datastore.events.append(NIDEvent(rawType: "test"))
        let mockSampling = NIDSamplingService()
        mockSampling._isSessionFlowSampled = true
        NeuroID.samplingService = mockSampling

        let mockNetwork = NIDNetworkServiceTestImpl()
        NeuroID.networkService = mockNetwork

        NeuroID._isSDKStarted = true

        NeuroID.clearSendOldFlowEvents {
            assert(NeuroID.datastore.events.count == 0)

            NeuroID._isSDKStarted = false
        }
    }
}

class NIDFormTests: BaseTestClass {
    override func setUpWithError() throws {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
    }

    override func setUp() {
        NeuroID._isSDKStarted = true
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

class NIDScreenTests: BaseTestClass {
    override func setUpWithError() throws {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
    }

    override func setUp() {
        NeuroID._isSDKStarted = true
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    func test_setScreenName_getScreenName() {
        clearOutDataStore()
        let expectedValue = "testScreen"
        let screenNameSet = NeuroID.setScreenName(expectedValue)

        let value = NeuroID.getScreenName()

        assert(value == expectedValue)
        assert(screenNameSet == true)

        assertStoredEventTypeAndCount(type: "MOBILE_METADATA_IOS", count: 1)
    }

    func test_setScreenName_getScreenName_withSpace() {
        clearOutDataStore()
        let expectedValue = "test Screen"
        let screenNameSet = NeuroID.setScreenName(expectedValue)

        let value = NeuroID.getScreenName()

        assert(value == "test%20Screen")
        assert(screenNameSet == true)

        assertStoredEventTypeAndCount(type: "MOBILE_METADATA_IOS", count: 1)
    }

    func test_setScreenName_not_started() {
        clearOutDataStore()
        NeuroID._isSDKStarted = false
        NeuroID.currentScreenName = ""
        let expectedValue = "test Screen"
        let screenNameSet = NeuroID.setScreenName(expectedValue)

        let value = NeuroID.getScreenName()

        assert(value != "test%20Screen")
        assert(screenNameSet == false)

        let allEvents = NeuroID.datastore.getAllEvents()
        assert(allEvents.count == 0)
    }
}

class NIDUserTests: BaseTestClass {
    override func setUpWithError() throws {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
    }

    override func setUp() {
        NeuroID._isSDKStarted = true
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }


    func test_getSessionID_objectLevel() {

        let expectedValue = "test_uid"

        NeuroID.sessionID = expectedValue

        let value = NeuroID.getSessionID()

        assert(NeuroID.sessionID == expectedValue)
        assert(value == expectedValue)
    }

    func test_getSessionID_dataStore() {
        let expectedValue = "test_uid"

        NeuroID.sessionID = nil

        let value = NeuroID.getSessionID()

        assert(value == "")
        assert(NeuroID.sessionID != expectedValue)
    }

    func test_getRegisteredUserID_objectLevel() {
        let expectedValue = "test_uid"

        NeuroID.registeredUserID = expectedValue

        let value = NeuroID.getRegisteredUserID()

        assert(NeuroID.registeredUserID == expectedValue)
        assert(value == expectedValue)

        NeuroID.registeredUserID = ""
    }

    func test_attemptedLoginWthUID() {
        let validID = NeuroID.attemptedLogin("valid_user_id")
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)
        
        assertStoredEventTypeAndCount(type: "ATTEMPTED_LOGIN", count: 0)
        assertStoredEventTypeAndCount(type: "LOG", count: 0)
        let allEvents = NeuroID.datastore.getAllEvents()
        let event = allEvents.filter { $0.type == "ATTEMPTED_LOGIN" }
        XCTAssertTrue(validID)
    }

    func test_attemptedLoginWthUIDQueued() {
        NeuroID._isSDKStarted = false
        let validID = NeuroID.attemptedLogin("valid_user_id")
        assertQueuedEventTypeAndCount(type: "ATTEMPTED_LOGIN", count: 1)
        assertQueuedEventTypeAndCount(type: "LOG", count: 1)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue, queued: true)
        let allEvents = NeuroID.datastore.getAndRemoveAllQueuedEvents()
        let event = allEvents.filter { $0.type == "ATTEMPTED_LOGIN" }
        XCTAssertTrue(validID)
        XCTAssertNotNil(event[0].uid!)
        // Value shoould be hashed/salted/prefixed
        XCTAssertEqual("valid_user_id", event[0].uid!)
    }

    func test_attemptedLoginWithInvalidID() {
        let invalidID = NeuroID.attemptedLogin("🤣")
        let allEvents = NeuroID.datastore.getAllEvents()
        let event = allEvents.filter { $0.type == "ATTEMPTED_LOGIN" }
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)
        
        XCTAssert(event.count == 1)
        XCTAssertTrue(invalidID)
        XCTAssertEqual(event[0].uid, "scrubbed-id-failed-validation")
        assertStoredEventTypeAndCount(type: "LOG", count: 0)
    }

    func test_attemptedLoginWithInvalidIDQueued() {
        NeuroID._isSDKStarted = false
        let invalidID = NeuroID.attemptedLogin("🤣")
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)
        
        assertQueuedEventTypeAndCount(type: "LOG", count: 2)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_FAIL.rawValue, queued: true)
        let allEvents = NeuroID.datastore.getAndRemoveAllQueuedEvents()
        let event = allEvents.filter { $0.type == "ATTEMPTED_LOGIN" }
        XCTAssert(event.count == 1)
        XCTAssertTrue(invalidID)
        XCTAssertEqual(event[0].uid, "scrubbed-id-failed-validation")
    }

    func test_attemptedLoginWithNoUID() {
        _ = NeuroID.attemptedLogin()
        
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)
        
        assertStoredEventTypeAndCount(type: "ATTEMPTED_LOGIN", count: 0)
        assertStoredEventTypeAndCount(type: "LOG", count: 0)
        let allEvents = NeuroID.datastore.getAllEvents()
        let event = allEvents.filter { $0.type == "ATTEMPTED_LOGIN" }
    }

    func test_attemptedLoginWithNoUIDQueued() {
        NeuroID._isSDKStarted = false
        _ = NeuroID.attemptedLogin()
        assertQueuedEventTypeAndCount(type: "ATTEMPTED_LOGIN", count: 1)
        assertQueuedEventTypeAndCount(type: "LOG", count: 1)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_NID_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_NID.rawValue, queued: true)
        let allEvents = NeuroID.datastore.getAndRemoveAllQueuedEvents()
        let event = allEvents.filter { $0.type == "ATTEMPTED_LOGIN" }
        XCTAssertEqual(event.last!.uid, "scrubbed-id-failed-validation")
    }

    func test_multipleAttemptedLogins() {
        _ = NeuroID.attemptedLogin()
        _ = NeuroID.attemptedLogin()
        usleep(500_000) // Sleep for 500ms (500,000 microseconds)
        assertStoredEventTypeAndCount(type: "ATTEMPTED_LOGIN", count: 0)
        assertStoredEventTypeAndCount(type: "LOG", count: 0)
    }
}

class NIDEnvTests: XCTestCase {
    func test_getEnvironment() {
        NeuroID.environment = Constants.environmentTest.rawValue
        assert(NeuroID.getEnvironment() == "TEST")
    }

    func test_setEnvironmentProduction_true() {
        NeuroID.environment = ""
        NeuroID.setEnvironmentProduction(true)

        // Should do nothing because deprecated
        assert(NeuroID.getEnvironment() == "")
    }

    func test_setEnvironmentProduction_false() {
        NeuroID.environment = ""
        NeuroID.setEnvironmentProduction(false)

        // Should do nothing because deprecated
        assert(NeuroID.getEnvironment() == "")
    }
}

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

class NIDSendTests: XCTestCase {
    func test_getCollectionEndpointURL() {
        NeuroID.setDevTestingURL()
        let expectedValue = "https://receiver.neuro-dev.com/c"

        let value = NeuroID.getCollectionEndpointURL()
        assert(value == expectedValue)
    }

    func test_initCollectionTimer_item() {
        NeuroID._isSDKStarted = false
        let expectation = XCTestExpectation(description: "Wait for 5 seconds")

        let workItem = DispatchWorkItem {
            NeuroID._isSDKStarted = true
            expectation.fulfill()
        }
        NeuroID.sendCollectionWorkItem = workItem

        NeuroID.initCollectionTimer()

        // Wait for the expectation to be fulfilled, or timeout after 7 seconds
        wait(for: [expectation], timeout: 7)

        assert(NeuroID._isSDKStarted)
        NeuroID._isSDKStarted = false
    }

    func test_initCollectionTimer_item_nil() {
        NeuroID._isSDKStarted = false
        let expectation = XCTestExpectation(description: "Wait for 5 seconds")

        // setting the item as nil so the queue won't run
        NeuroID.sendCollectionWorkItem = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            expectation.fulfill()
        }

        NeuroID.initCollectionTimer()

        // Wait for the expectation to be fulfilled, or timeout after 7 seconds
        wait(for: [expectation], timeout: 7)

        assert(!NeuroID._isSDKStarted)
        NeuroID._isSDKStarted = false
    }

    //    createCollectionWorkItem // Not sure how to test because it returns an item that always exists
}

class NIDLogTests: XCTestCase {
    func test_enableLogging_true() {
        NeuroID.enableLogging(true)

        assert(NeuroID.showLogs)
    }

    func test_enableLogging_false() {
        NeuroID.enableLogging(false)

        assert(!NeuroID.showLogs)
    }
}

class NIDRNTests: XCTestCase {
    override func setUp() {
        NeuroID.isRN = false
        NeuroID.clientKey = nil
    }

    let configOptionsTrue = [RNConfigOptions.usingReactNavigation.rawValue: true, RNConfigOptions.isAdvancedDevice.rawValue: false]
    let configOptionsFalse = [RNConfigOptions.usingReactNavigation.rawValue: false]
    let configOptionsInvalid = ["foo": "bar"]
    let configOptionsNonNil = [RNConfigOptions.advancedDeviceKey.rawValue: "testkey"]
    
    func assertConfigureTests(defaultValue: Bool, expectedValue: Bool) {
        assert(NeuroID.isRN)
        let storedValue = NeuroID.rnOptions[.usingReactNavigation] as? Bool ?? defaultValue
        assert(storedValue == expectedValue)
        assert(NeuroID.rnOptions.count == 1)
    }

    func test_isRN() {
        assert(!NeuroID.isRN)
        NeuroID.setIsRN()

        assert(NeuroID.isRN)
    }

    func test_configure_usingReactNavigation_true() {
        assert(!NeuroID.isRN)
        let configured = NeuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: configOptionsTrue
        )

        assert(configured)
        assertConfigureTests(defaultValue: false, expectedValue: true)
    }

    func test_configure_usingReactNavigation_false() {
        assert(!NeuroID.isRN)
        let configured = NeuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: configOptionsFalse
        )

        assert(configured)
        assertConfigureTests(defaultValue: true, expectedValue: false)
    }

    func test_configure_invalid_key() {
        assert(!NeuroID.isRN)
        let configured = NeuroID.configure(
            clientKey: "key_test_XXXXXXXXXXX",
            rnOptions: configOptionsInvalid
        )

        assert(configured)
        assertConfigureTests(defaultValue: true, expectedValue: false)
    }

    func test_getOptionValueBool_true() {
        assert(!NeuroID.isRN)
        let value = NeuroID.getOptionValueBool(rnOptions: configOptionsTrue, configOptionKey: .usingReactNavigation)

        assert(value)
    }

    func test_getOptionValueBool_false() {
        assert(!NeuroID.isRN)
        let value = NeuroID.getOptionValueBool(rnOptions: configOptionsFalse, configOptionKey: .usingReactNavigation)

        assert(!value)
    }

    func test_getOptionValueBool_invalid() {
        assert(!NeuroID.isRN)
        let value = NeuroID.getOptionValueBool(rnOptions: configOptionsInvalid, configOptionKey: .usingReactNavigation)

        assert(!value)
    }
    
    func test_getOptionValueString_nonNil() {
        assert(!NeuroID.isRN)
        let value = NeuroID.getOptionValueString(rnOptions: configOptionsNonNil, configOptionKey: .advancedDeviceKey)

        assert(value == "testkey")
    }
    
    func test_getOptionValueString_nil() {
        assert(!NeuroID.isRN)
        // does not contain advanced device key, therfore nil
        let value = NeuroID.getOptionValueString(rnOptions: configOptionsFalse, configOptionKey: .advancedDeviceKey)

        assert(value == "")
    }
}

// swizzle
// initTimer
// send

// groupAndPOST
// post

// logInfo
// logError
// logFault
// logDebug
// logDefault
// osLog

// saveDebugJSON
