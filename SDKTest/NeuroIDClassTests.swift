//
//  NeuroIDClassTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 4/5/23.
//

@testable import NeuroID
import XCTest

class NeuroIDClassTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"

    // Keys for storage:
    let localStorageNIDStopAll = Constants.storageLocalNIDStopAllKey.rawValue
    let clientKeyKey = Constants.storageClientKey.rawValue
    let tabIdKey = Constants.storageTabIDKey.rawValue

    let mockService = MockDeviceSignalService()

    func clearOutDataStore() {
        let _ = DataStore.getAndRemoveAllEvents()
    }

    override func setUpWithError() throws {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
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
            let allEvents = DataStore.getAllEvents()

            let validEvent = allEvents.filter { $0.type == "ADVANCED_DEVICE_REQUEST" }
            XCTAssertTrue(validEvent.count == 1)
        }
    }

    func assertDataStoreCount(count: Int) {
        let allEvents = DataStore.getAllEvents()
        assert(allEvents.count == count)
    }

    func assertStoredEventCount(type: String, count: Int) {
        let allEvents = DataStore.getAllEvents()
        let validEvent = allEvents.filter { $0.type == type }

        assert(validEvent.count == count)
    }

    func assertStoredEventTypeAndCount(type: String, count: Int, queued: Bool?) {
        let allEvents = queued ?? false ? DataStore.getAndRemoveAllQueuedEvents() : DataStore.getAllEvents()

        let validEvent = allEvents.filter { $0.type == type }

        assert(validEvent.count == count)
        assert(validEvent[0].type == type)
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
        assertStoredEventTypeAndCount(type: "LOG", count: 1, queued: true)

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
            assert(DataStore.events.count >= 2)
            self.assertStoredEventCount(type: "CREATE_SESSION", count: 1)
            self.assertStoredEventCount(type: "MOBILE_METADATA_IOS", count: 1)
        }
    }

    func test_start_success_queuedEvent() {
        _ = NeuroID.stop()
        let setSessionIDRes = NeuroID.setSessionID("test_uid", false)
        assert(setSessionIDRes)
        NeuroID._isSDKStarted = false

        // pre tests
        assert(!NeuroID.isSDKStarted)

        // action
        NeuroID.start { started in

            // post action test
            assert(started)
            assert(NeuroID.isSDKStarted)
            assert(DataStore.events.count == 14)

            self.assertStoredEventCount(type: "CREATE_SESSION", count: 1)
            self.assertStoredEventCount(type: "MOBILE_METADATA_IOS", count: 1)
            self.assertStoredEventCount(type: "SET_USER_ID", count: 1)
            self.assertStoredEventCount(type: "APPLICATION_METADATA", count: 1)
            self.assertStoredEventCount(type: "SET_VARIABLE", count: 4)
            self.assertStoredEventCount(type: "LOG", count: 6)
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

class NIDRegistrationTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"

    func clearOutDataStore() {
        DataStore.removeSentEvents()
    }

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

    func assertDataStoreCount(count: Int) {
        let allEvents = DataStore.getAllEvents()
        assert(allEvents.count == count)
    }

    func assertStoredEventTypeAndCount(type: String, count: Int) {
        let allEvents = DataStore.getAllEvents()
        let validEvent = allEvents.filter { $0.type == type }

        assert(validEvent.count == count)
        assert(validEvent[0].type == type)
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

        let allEvents = DataStore.getAllEvents()
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

        XCTAssertTrue(event.type == NIDSessionEventName.setVariable.rawValue)
        XCTAssertTrue(event.key == "t")
        XCTAssertTrue(event.v == "v")
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 1)
    }

    func test_setVariable() {
        clearOutDataStore()
        let event = NeuroID.setVariable(key: "t", value: "v")

        XCTAssertTrue(event.type == NIDSessionEventName.setVariable.rawValue)
        XCTAssertTrue(event.key == "t")
        XCTAssertTrue(event.v == "v")
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 1)
    }
}

class NIDSessionTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"

    let clientIdKey = Constants.storageClientIDKey.rawValue

    func clearOutDataStore() {
        DataStore.removeSentEvents()
    }

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

    func assertStoredEventTypeAndCount(type: String, count: Int) {
        let allEvents = DataStore.getAllEvents()
        let validEvent = allEvents.filter { $0.type == type }

        assert(validEvent.count == count)
        assert(validEvent[0].type == type)
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
        DataStore.removeSentEvents()

        NeuroID.createSession()

        assertStoredEventTypeAndCount(type: "CREATE_SESSION", count: 1)
        assertStoredEventTypeAndCount(type: "MOBILE_METADATA_IOS", count: 1)
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

class NIDNewSessionTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"
    let clientIdKey = Constants.storageClientIDKey.rawValue

    func clearOutDataStore() {
        DataStore.removeSentEvents()
        _ = DataStore.getAndRemoveAllQueuedEvents()
    }

    override func setUpWithError() throws {
        NeuroID.configService = MockConfigService()
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
    }

    override func tearDown() {
        _ = NeuroID.stop()
        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    func assertStoredEventTypeAndCount(type: String, count: Int, skipType: Bool? = false) {
        let allEvents = DataStore.getAllEvents()
        let validEvent = allEvents.filter { $0.type == type }

        assert(validEvent.count == count)
        if !skipType! {
            assert(validEvent[0].type == type)
        }
    }

    func assertQueuedEventTypeAndCount(type: String, count: Int, skipType: Bool? = false) {
        let allEvents = DataStore.queuedEvents
        let validEvent = allEvents.filter { $0.type == type }

        assert(validEvent.count == count)
        if !skipType! {
            assert(validEvent[0].type == type)
        }
    }

    func assertDatastoreEventOrigin(type: String, origin: String, originCode: String, queued: Bool) {
        let allEvents = queued ? DataStore.queuedEvents : DataStore.getAllEvents()
        let validEvents = allEvents.filter { $0.type == type }

        let originEvent = validEvents.filter { $0.key == "sessionIdSource" }
        assert(originEvent.count == 1)
        assert(originEvent[0].v == origin)

        let originCodeEvent = validEvents.filter { $0.key == "sessionIdCode" }
        assert(originCodeEvent.count == 1)
        assert(originCodeEvent[0].v == originCode)
    }

    func assertSessionStartedTests(_ sessionRes: SessionStartResult) {
        assert(sessionRes.started)
        assert(NeuroID._isSDKStarted)
        assert(NeuroID.sendCollectionWorkItem == nil) // In real world it would != nil but because of tests we don't want to trigger a re-occuring event

        assertStoredEventTypeAndCount(type: NIDSessionEventName.createSession.rawValue, count: 1)
        assertStoredEventTypeAndCount(type: NIDSessionEventName.mobileMetadataIOS.rawValue, count: 1)
        assertStoredEventTypeAndCount(type: NIDSessionEventName.setUserId.rawValue, count: 1)
        assert(DataStore.queuedEvents.isEmpty)
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

        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue, queued: false)
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

        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_NID_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_NID.rawValue, queued: false)
    }

    func test_startSession_success_no_id_sdk_started() {
        NeuroID.sessionID = nil
        NeuroID._isSDKStarted = true

        let expectedValue = "mySessionID"
        NeuroID.startSession { sessionRes in
            self.assertSessionStartedTests(sessionRes)
            assert(expectedValue != sessionRes.sessionID)
        }
        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_NID_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_NID.rawValue, queued: false)
    }

    func test_startSession_success_id_sdk_started() {
        NeuroID.sessionID = nil
        NeuroID._isSDKStarted = true

        let expectedValue = "mySessionID"
        NeuroID.startSession(expectedValue) { sessionRes in
            self.assertSessionStartedTests(sessionRes)
            assert(expectedValue == sessionRes.sessionID)
        }
        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue, queued: false)
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
        DataStore.events.append(NIDEvent(rawType: "test"))
        let mockSampling = NIDSamplingService()
        mockSampling._isSessionFlowSampled = false
        NeuroID.samplingService = mockSampling

        NeuroID.clearSendOldFlowEvents {
            assert(DataStore.events.count == 0)

            NeuroID._isSDKStarted = false
        }
    }

    func test_clearSendOldFlowEvents_sampled() {
        DataStore.events.append(NIDEvent(rawType: "test"))
        let mockSampling = NIDSamplingService()
        mockSampling._isSessionFlowSampled = true
        NeuroID.samplingService = mockSampling

        let mockNetwork = NIDNetworkServiceTestImpl()
        NeuroID.networkService = mockNetwork

        NeuroID._isSDKStarted = true

        NeuroID.clearSendOldFlowEvents {
            assert(DataStore.events.count == 0)

            NeuroID._isSDKStarted = false
        }
    }
}

class NIDFormTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"
    let clientIdKey = Constants.storageClientIDKey.rawValue

    func clearOutDataStore() {
        DataStore.removeSentEvents()
    }

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

    func assertStoredEventTypeAndCount(type: String, count: Int) {
        let allEvents = DataStore.getAllEvents()
        let validEvent = allEvents.filter { $0.type == type }

        assert(validEvent.count == count)
        assert(validEvent[0].type == type)
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

class NIDScreenTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"

    func clearOutDataStore() {
        DataStore.removeSentEvents()
    }

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

    func assertStoredEventTypeAndCount(type: String, count: Int) {
        let allEvents = DataStore.getAllEvents()
        let validEvent = allEvents.filter { $0.type == type }

        assert(validEvent.count == count)
        assert(validEvent[0].type == type)
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

        let allEvents = DataStore.getAllEvents()
        assert(allEvents.count == 0)
    }
}

class NIDUserTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"

    func clearOutDataStore() {
        DataStore.removeSentEvents()
        let _ = DataStore.getAndRemoveAllQueuedEvents()
    }

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

    func assertStoredEventTypeAndCount(type: String, count: Int, skipType: Bool? = false) {
        let allEvents = DataStore.getAllEvents()
        let validEvent = allEvents.filter { $0.type == type }

        assert(validEvent.count == count)
        if !skipType! {
            assert(validEvent[0].type == type)
        }
    }

    func assertQueuedEventTypeAndCount(type: String, count: Int, skipType: Bool? = false) {
        let allEvents = DataStore.queuedEvents
        let validEvent = allEvents.filter { $0.type == type }

        assert(validEvent.count == count)
        if !skipType! {
            assert(validEvent[0].type == type)
        }
    }

    func assertDatastoreEventOrigin(type: String, origin: String, originCode: String, queued: Bool) {
        let allEvents = queued ? DataStore.queuedEvents : DataStore.getAllEvents()
        let validEvents = allEvents.filter { $0.type == type }

        let originEvent = validEvents.filter { $0.key == "sessionIdSource" }
        assert(originEvent.count == 1)
        assert(originEvent[0].v == origin)

        let originCodeEvent = validEvents.filter { $0.key == "sessionIdCode" }
        assert(originCodeEvent.count == 1)
        assert(originCodeEvent[0].v == originCode)
    }

    func test_validatedUserID_valid_id() {
        let validIdentifiers = [
            "123",
            "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789",
            "a-A_1.0",
        ]

        for identifier in validIdentifiers {
            let userNameSet = NeuroID.validateIdentifier(identifier)
            assert(userNameSet == true)
        }
    }

    func test_validatedUserID_invalid_id() {
        let invalidIdentifiers = [
            "",
            "1",
            "12",
            "to_long_789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789",
            "this_is_way_to_long_0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789",
            "invalid characters",
            "invalid*ch@racters",
        ]

        for identifier in invalidIdentifiers {
            let userNameSet = NeuroID.validateIdentifier(identifier)
            assert(userNameSet == false)
        }
    }

    func test_scrubEmailId() {
        let id = "tt@test.com"
        let expectedId = "t*@test.com"
        let scrubbedId = NeuroID.scrubIdentifier(id)
        XCTAssertEqual(scrubbedId, expectedId)
    }

    func test_unScrubbedID() {
        let id = "123_testing123"
        let expectedId = "123_testing123"
        let unscrubbedId = NeuroID.scrubIdentifier(id)
        XCTAssertEqual(unscrubbedId, expectedId)
    }

    func test_scrubSSN() {
        let id = "123-23-4568"
        let expectedId = "***-**-****"
        let scrubbedId = NeuroID.scrubIdentifier(id)
        XCTAssertEqual(scrubbedId, expectedId)
    }

    func test_setGenericIdentifier_valid_id_started() {
        NeuroID._isSDKStarted = true

        let expectedValue = "myTestUserID"
        let result = NeuroID.setGenericIdentifier(type: .userID, genericIdentifier: expectedValue, userGenerated: true)

        assert(result == true)
        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assert(DataStore.queuedEvents.count == 0)
    }

    func test_setGenericIdentifier_valid_id_queued() {
        NeuroID._isSDKStarted = false
        clearOutDataStore()

        let expectedValue = "myTestUserID"
        let result = NeuroID.setGenericIdentifier(type: .userID, genericIdentifier: expectedValue, userGenerated: true)

        assert(result == true)
        assert(DataStore.events.count == 0)
        assertQueuedEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assertQueuedEventTypeAndCount(type: "SET_VARIABLE", count: 4)
    }

    func test_setGenericIdentifier_valid_registered_id_started() {
        NeuroID._isSDKStarted = true

        let expectedValue = "myTestUserID"
        let result = NeuroID.setGenericIdentifier(type: .registeredUserID, genericIdentifier: expectedValue, userGenerated: true)

        assert(result == true)
        assertStoredEventTypeAndCount(type: "SET_REGISTERED_USER_ID", count: 1)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assert(DataStore.queuedEvents.count == 0)
    }

    func test_setGenericIdentifier_valid_registered_id_queued() {
        NeuroID._isSDKStarted = false
        clearOutDataStore()

        let expectedValue = "myTestUserID"
        let result = NeuroID.setGenericIdentifier(type: .registeredUserID, genericIdentifier: expectedValue, userGenerated: true)

        assert(result == true)
        assert(DataStore.events.count == 0)
        assertQueuedEventTypeAndCount(type: "SET_REGISTERED_USER_ID", count: 1)
        assertQueuedEventTypeAndCount(type: "SET_VARIABLE", count: 4)
    }

    func test_setGenericIdentifier_invalid_id_started() {
        NeuroID._isSDKStarted = true
        clearOutDataStore()
        let expectedValue = "$!&*"
        let result = NeuroID.setGenericIdentifier(type: .userID, genericIdentifier: expectedValue, userGenerated: true)

        assert(result == false)
        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 0, skipType: true)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_FAIL.rawValue, queued: false)
    }

    func test_setGenericIdentifier_invalid_id_queued() {
        NeuroID._isSDKStarted = false
        clearOutDataStore()

        let expectedValue = "$!&*"
        let result = NeuroID.setGenericIdentifier(type: .userID, genericIdentifier: expectedValue, userGenerated: true)

        assert(result == false)
        assert(DataStore.events.count == 0)
        assertQueuedEventTypeAndCount(type: "SET_USER_ID", count: 0, skipType: true)
        assertQueuedEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_FAIL.rawValue, queued: true)
    }

    func test_setSessionID_started_customer_origin() {

        let expectedValue = "test_uid"

        let fnSuccess = NeuroID.setSessionID(expectedValue, true)

        assert(fnSuccess)
        assert(NeuroID.sessionID == expectedValue)

        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue, queued: false)

        /* The following events are in the DataStore now.*/
        // Log
        // Set Variable (sessionIdCode)
        // Set Variable (sessionIdSource)
        // Set Variable (sessionId)
        // Set Variable (sessionIdType)
        // SET_USER_ID
        assert(DataStore.events.count == 6)
    }

    func test_setSessionID_pre_start_customer_origin() {
        _ = NeuroID.stop()

        let expectedValue = "test_uid"

        let fnSuccess = NeuroID.setSessionID(expectedValue, true)

        assert(fnSuccess == true)
        assert(NeuroID.sessionID == expectedValue)

        //        assert(DataStore.events.count == 0) "NETWORK_STATE" event present
        assertQueuedEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assertQueuedEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue, queued: true)
    }

    func test_setSessionID_started_nid_origin() {

        let expectedValue = "test_uid"

        let fnSuccess = NeuroID.setSessionID(expectedValue, false)

        assert(fnSuccess)
        assert(NeuroID.sessionID == expectedValue)

        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_NID_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_NID.rawValue, queued: false)

        /* The following events are in the DataStore now.*/
        // Log
        // Set Variable (sessionIdCode)
        // Set Variable (sessionIdSource)
        // Set Variable (sessionId)
        // Set Variable (sessionIdType)
        // SET_USER_ID
        assert(DataStore.events.count == 6)
    }

    func test_setSessionID_pre_start_nid_origin() {
        _ = NeuroID.stop()

        let expectedValue = "test_uid"

        let fnSuccess = NeuroID.setSessionID(expectedValue, false)

        assert(fnSuccess == true)
        assert(NeuroID.sessionID == expectedValue)
        assert(DataStore.events.count == 0)
        assertQueuedEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assertQueuedEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_NID_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_NID.rawValue, queued: true)
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

    func test_setRegisteredUserID_started() {
        let expectedValue = "test_ruid"

        let fnSuccess = NeuroID.setRegisteredUserID(expectedValue)

        assert(fnSuccess == true)
        assert(NeuroID.registeredUserID == expectedValue)

        assertStoredEventTypeAndCount(type: "SET_REGISTERED_USER_ID", count: 1)
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue, queued: false)
        assertStoredEventTypeAndCount(type: "LOG", count: 1)
        assert(DataStore.queuedEvents.count == 0)

        NeuroID.registeredUserID = ""
    }

    func test_setRegisteredUserID_pre_start() {
        _ = NeuroID.stop()

        let expectedValue = "test_ruid"

        let fnSuccess = NeuroID.setRegisteredUserID(expectedValue)

        assert(fnSuccess == true)
        assert(NeuroID.registeredUserID == expectedValue)

//        assert(DataStore.events.count == 0)
        assertQueuedEventTypeAndCount(type: "SET_REGISTERED_USER_ID", count: 1)
        assertQueuedEventTypeAndCount(type: "SET_VARIABLE", count: 4)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue, queued: true)
        assertQueuedEventTypeAndCount(type: "LOG", count: 1)
        NeuroID.registeredUserID = ""
    }

    func test_setRegisteredUserID_already_set() {
        clearOutDataStore()
        NeuroID._isSDKStarted = true
        NeuroID.registeredUserID = "setID"

        let expectedValue = "test_ruid"

        let fnSuccess = NeuroID.setRegisteredUserID(expectedValue)

        assert(fnSuccess == true)
        assert(NeuroID.registeredUserID == expectedValue)

        assertStoredEventTypeAndCount(type: "LOG", count: 2)
        assert(DataStore.queuedEvents.count == 0)

        NeuroID.registeredUserID = ""
    }

    func test_setRegisteredUserID_same_value() {
        clearOutDataStore()

        let expectedValue = "test_ruid"

        NeuroID.registeredUserID = expectedValue

        let fnSuccess = NeuroID.setRegisteredUserID(expectedValue)

        assert(fnSuccess == true)
        assert(NeuroID.registeredUserID == expectedValue)

        assertStoredEventTypeAndCount(type: "SET_REGISTERED_USER_ID", count: 1)

        NeuroID.registeredUserID = ""
    }

    func test_attemptedLoginWthUID() {
        let validID = NeuroID.attemptedLogin("valid_user_id")
        assertStoredEventTypeAndCount(type: "ATTEMPTED_LOGIN", count: 1)
        assertStoredEventTypeAndCount(type: "LOG", count: 1)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue, queued: false)
        let allEvents = DataStore.getAllEvents()
        let event = allEvents.filter { $0.type == "ATTEMPTED_LOGIN" }
        XCTAssertTrue(validID)
        XCTAssertNotNil(event[0].uid!)
        // Value shoould be hashed/salted/prefixed
        XCTAssertEqual("valid_user_id", event[0].uid!)
    }

    func test_attemptedLoginWthUIDQueued() {
        NeuroID._isSDKStarted = false
        let validID = NeuroID.attemptedLogin("valid_user_id")
        assertQueuedEventTypeAndCount(type: "ATTEMPTED_LOGIN", count: 1)
        assertQueuedEventTypeAndCount(type: "LOG", count: 1)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_CUSTOMER.rawValue, queued: true)
        let allEvents = DataStore.getAndRemoveAllQueuedEvents()
        let event = allEvents.filter { $0.type == "ATTEMPTED_LOGIN" }
        XCTAssertTrue(validID)
        XCTAssertNotNil(event[0].uid!)
        // Value shoould be hashed/salted/prefixed
        XCTAssertEqual("valid_user_id", event[0].uid!)
    }

    func test_attemptedLoginWithInvalidID() {
        let invalidID = NeuroID.attemptedLogin("🤣")
        let allEvents = DataStore.getAllEvents()
        let event = allEvents.filter { $0.type == "ATTEMPTED_LOGIN" }
        XCTAssert(event.count == 1)
        XCTAssertTrue(invalidID)
        XCTAssertEqual(event[0].uid, "scrubbed-id-failed-validation")
        assertStoredEventTypeAndCount(type: "LOG", count: 2)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_FAIL.rawValue, queued: false)
    }

    func test_attemptedLoginWithInvalidIDQueued() {
        NeuroID._isSDKStarted = false
        let invalidID = NeuroID.attemptedLogin("🤣")
        assertQueuedEventTypeAndCount(type: "LOG", count: 2)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_CUSTOMER_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_FAIL.rawValue, queued: true)
        let allEvents = DataStore.getAndRemoveAllQueuedEvents()
        let event = allEvents.filter { $0.type == "ATTEMPTED_LOGIN" }
        XCTAssert(event.count == 1)
        XCTAssertTrue(invalidID)
        XCTAssertEqual(event[0].uid, "scrubbed-id-failed-validation")
    }

    func test_attemptedLoginWithNoUID() {
        _ = NeuroID.attemptedLogin()
        assertStoredEventTypeAndCount(type: "ATTEMPTED_LOGIN", count: 1)
        assertStoredEventTypeAndCount(type: "LOG", count: 1)
        let allEvents = DataStore.getAllEvents()
        let event = allEvents.filter { $0.type == "ATTEMPTED_LOGIN" }
        XCTAssertEqual(event.last!.uid, "scrubbed-id-failed-validation")
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_NID_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_NID.rawValue, queued: false)
    }

    func test_attemptedLoginWithNoUIDQueued() {
        NeuroID._isSDKStarted = false
        _ = NeuroID.attemptedLogin()
        assertQueuedEventTypeAndCount(type: "ATTEMPTED_LOGIN", count: 1)
        assertQueuedEventTypeAndCount(type: "LOG", count: 1)
        assertDatastoreEventOrigin(type: "SET_VARIABLE", origin: SessionOrigin.NID_ORIGIN_NID_SET.rawValue, originCode: SessionOrigin.NID_ORIGIN_CODE_NID.rawValue, queued: true)
        let allEvents = DataStore.getAndRemoveAllQueuedEvents()
        let event = allEvents.filter { $0.type == "ATTEMPTED_LOGIN" }
        XCTAssertEqual(event.last!.uid, "scrubbed-id-failed-validation")
    }

    func test_multipleAttemptedLogins() {
        _ = NeuroID.attemptedLogin()
        _ = NeuroID.attemptedLogin()
        assertStoredEventTypeAndCount(type: "ATTEMPTED_LOGIN", count: 2)
        assertStoredEventTypeAndCount(type: "LOG", count: 2)
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

class NIDClientSiteIdTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"

    // Keys for storage:
    let clientKeyKey = Constants.storageClientKey.rawValue
    let cidKey = Constants.storageClientIDKey.rawValue

    func test_getClientID() {
        UserDefaults.standard.setValue("test-cid", forKey: cidKey)
        NeuroID.clientID = nil
        let value = NeuroID.getClientID()

        assert(value == "test-cid")
    }

    func test_getClientId_existing() {
        let expectedValue = "test-cid"

        NeuroID.clientID = expectedValue
        UserDefaults.standard.set(expectedValue, forKey: cidKey)

        let value = NeuroID.getClientID()

        assert(value == expectedValue)
    }

    func test_getClientId_random() {
        let expectedValue = "test_cid"

        UserDefaults.standard.set(expectedValue, forKey: cidKey)

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

    func test_validateClientKey_valid_live() {
        let value = NeuroID.validateClientKey("key_live_XXXXXXXXXXX")

        assert(value)
    }

    func test_validateClientKey_valid_test() {
        let value = NeuroID.validateClientKey("key_test_XXXXXXXXXXX")

        assert(value)
    }

    func test_validateClientKey_invalid_env() {
        let value = NeuroID.validateClientKey("key_foo_XXXXXXXXXXX")

        assert(!value)
    }

    func test_validateClientKey_invalid_random() {
        let value = NeuroID.validateClientKey("sdfsdfsdfsdf")

        assert(!value)
    }

    func test_validateSiteID_valid() {
        let value = NeuroID.validateSiteID("form_peaks345")

        assert(value)
    }

    func test_validateSiteID_invalid_bad() {
        let value = NeuroID.validateSiteID("badSiteID")

        assert(!value)
    }

    func test_validateSiteID_invalid_short() {
        let value = NeuroID.validateSiteID("form_abc123")

        assert(!value)
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
