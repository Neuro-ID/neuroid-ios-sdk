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

    func clearOutDataStore() {
        let _ = DataStore.getAndRemoveAllEvents()
    }

    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey)
    }

    override func setUp() {
        let _ = NeuroID.start()
    }

    override func tearDown() {
        NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
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

    func assertStoredEventTypeAndCount(type: String, count: Int) {
        let allEvents = DataStore.getAllEvents()
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

        NeuroID.configure(clientKey: clientKey)

        let clientKeyValue = UserDefaults.standard.string(forKey: clientKeyKey)
        assert(clientKeyValue == clientKey)

        let tabIdValue = UserDefaults.standard.string(forKey: tabIdKey)
        assert(tabIdValue == nil)

        assertStoredEventCount(type: "CREATE_SESSION", count: 0)

        assert(NeuroID.environment == "\(Constants.environmentLive.rawValue)")
    }

    func test_configure_invalidKey() {
        clearOutDataStore()
        // remove things configured in setup
        NeuroID.environment = Constants.environmentTest.rawValue
        NeuroID.clientKey = nil
        UserDefaults.standard.setValue(nil, forKey: clientKeyKey)
        UserDefaults.standard.setValue("testTabId", forKey: tabIdKey)

        NeuroID.configure(clientKey: "invalid_key")

        let clientKeyValue = UserDefaults.standard.string(forKey: clientKeyKey)
        assert(clientKeyValue == nil)

        let tabIdValue = UserDefaults.standard.string(forKey: tabIdKey)
        assert(tabIdValue == "testTabId")

        assertStoredEventCount(type: "CREATE_SESSION", count: 0)

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
        let started = NeuroID.start()
        assert(!started)
        // post action test
        assert(!NeuroID.isSDKStarted)
    }

    func test_start_success() {
        tearDown()
        NeuroID._isSDKStarted = false

        // pre tests
        assert(!NeuroID.isSDKStarted)

        // action
        let started = NeuroID.start()

        // post action test
        assert(started)
        assert(NeuroID.isSDKStarted)
        assert(DataStore.events.count == 2)
        assertStoredEventCount(type: "CREATE_SESSION", count: 1)
        assertStoredEventCount(type: "MOBILE_METADATA_IOS", count: 1)
    }

    func test_start_success_queuedEvent() {
        NeuroID.stop()
        let setUserIDRes = NeuroID.setUserID("test_uid")

        assert(setUserIDRes)

        NeuroID._isSDKStarted = false

        // pre tests
        assert(!NeuroID.isSDKStarted)

        // action
        let started = NeuroID.start()

        // post action test
        assert(started)
        assert(NeuroID.isSDKStarted)

        assert(DataStore.events.count == 3)
        assertStoredEventCount(type: "CREATE_SESSION", count: 1)
        assertStoredEventCount(type: "MOBILE_METADATA_IOS", count: 1)
        assertStoredEventCount(type: "SET_USER_ID", count: 1)
    }

    func test_stop() {
        NeuroID._isSDKStarted = true
        assert(NeuroID.isSDKStarted)

        NeuroID.stop()
        assert(!NeuroID.isSDKStarted)
    }

    func test_saveEventToLocalDataStore() {
        let event = NIDEvent(type: NIDEventName.heartbeat)

        NeuroID.saveEventToLocalDataStore(event)

        assertStoredEventTypeAndCount(type: "HEARTBEAT", count: 1)
    }

    func test_getSDKVersion() {
        let expectedValue = ParamsCreator.getSDKVersion()

        let value = NeuroID.getSDKVersion()

        assert(value == expectedValue)
    }
}

class NIDRegistrationTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"

    func clearOutDataStore() {
        DataStore.removeSentEvents()
    }

    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey)
    }

    override func setUp() {
        let _ = NeuroID.start()
    }

    override func tearDown() {
        NeuroID.stop()

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
        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 1)
    }
}

class NIDSessionTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"

    let sessionIdKey = Constants.storageSessionIDKey.rawValue
    let clientIdKey = Constants.storageClientIDKey.rawValue

    func clearOutDataStore() {
        DataStore.removeSentEvents()
    }

    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey)
    }

    override func setUp() {
        let _ = NeuroID.start()
    }

    override func tearDown() {
        NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    func assertStoredEventTypeAndCount(type: String, count: Int) {
        let allEvents = DataStore.getAllEvents()
        let validEvent = allEvents.filter { $0.type == type }

        assert(validEvent.count == count)
        assert(validEvent[0].type == type)
    }

    func test_clearStoredSessionID() {
        UserDefaults.standard.set("session", forKey: sessionIdKey)
        UserDefaults.standard.set("client", forKey: clientIdKey)

        NeuroID.clearStoredSessionID()

        let session = UserDefaults.standard.string(forKey: sessionIdKey)
        let client = UserDefaults.standard.string(forKey: clientIdKey)

        assert(session == nil)
        assert(client != nil)
    }

    func test_getSessionID() {
        let expectedValue = "session"
        UserDefaults.standard.set(expectedValue, forKey: sessionIdKey)

        let value = NeuroID.getSessionID()

        assert(value == expectedValue)
    }

    func test_getSessionID_existing() {
        let expectedValue = "test_sid"
        UserDefaults.standard.set(expectedValue, forKey: sessionIdKey)

        let value = NeuroID.getSessionID()

        assert(value == expectedValue)
    }

    func test_getSessionID_random() {
        UserDefaults.standard.set(nil, forKey: sessionIdKey)

        let value = NeuroID.getSessionID()

        assert(value != "")
        assert(value.count == 36)
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
        NeuroID.stop()
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

    let sessionIdKey = Constants.storageSessionIDKey.rawValue
    let clientIdKey = Constants.storageClientIDKey.rawValue

    func clearOutDataStore() {
        DataStore.removeSentEvents()
        let _ = DataStore.getAndRemoveAllQueuedEvents()
    }

    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey)
    }

    override func tearDown() {
        NeuroID.stop()
        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    func assertStoredEventTypeAndCount(type: String, count: Int) {
        let allEvents = DataStore.getAllEvents()
        let validEvent = allEvents.filter { $0.type == type }

        assert(validEvent.count == count)
        assert(validEvent[0].type == type)
    }

    func assertQueuedEventTypeAndCount(type: String, count: Int) {
        let allEvents = DataStore.queuedEvents
        let validEvent = allEvents.filter { $0.type == type }

        assert(validEvent.count == count)
        assert(validEvent[0].type == type)
    }

    //    clearSessionVariables
    func test_clearSessionVariables() {
        NeuroID.userID = "myUserID"
        NeuroID.registeredUserID = "myRegisteredUserID"

        NeuroID.clearSessionVariables()

        assert(NeuroID.userID == nil)
        assert(NeuroID.registeredUserID == "")
    }

    func test_startSession_success_id() {
        NeuroID.userID = nil
        NeuroID._isSDKStarted = false

        let expectedValue = "mySessionID"
        let (started, id) = NeuroID.startSession(expectedValue)

        assert(started)
        assert(expectedValue == id)
        assert(NeuroID._isSDKStarted)
        assert(NeuroID.sendCollectionWorkItem == nil) // In real world it would != nil but because of tests we don't want to trigger a re-occuring event

        assertStoredEventTypeAndCount(type: NIDSessionEventName.createSession.rawValue, count: 1)
        assertStoredEventTypeAndCount(type: NIDSessionEventName.mobileMetadataIOS.rawValue, count: 1)
        assertStoredEventTypeAndCount(type: NIDSessionEventName.setUserId.rawValue, count: 1)
        assert(DataStore.queuedEvents.isEmpty)
    }

    func test_startSession_success_no_id() {
        NeuroID.userID = nil
        NeuroID._isSDKStarted = false

        let expectedValue = "mySessionID"
        let (started, id) = NeuroID.startSession()

        assert(started)
        assert(expectedValue != id)
        assert(NeuroID._isSDKStarted)
        assert(NeuroID.sendCollectionWorkItem == nil) // In real world it would != nil but because of tests we don't want to trigger a re-occuring event

        assertStoredEventTypeAndCount(type: NIDSessionEventName.createSession.rawValue, count: 1)
        assertStoredEventTypeAndCount(type: NIDSessionEventName.mobileMetadataIOS.rawValue, count: 1)
        assertStoredEventTypeAndCount(type: NIDSessionEventName.setUserId.rawValue, count: 1)
        assert(DataStore.queuedEvents.isEmpty)
    }

    func test_startSession_failure_clientKey() {
        NeuroID.clientKey = nil

        let (started, id) = NeuroID.startSession()

        assert(!started)
        assert(id == "")
        assert(!NeuroID._isSDKStarted)
        assert(NeuroID.sendCollectionWorkItem == nil) // In real world it would != nil but because of tests we don't want to trigger a re-occuring event
    }

    func test_startSession_failure_userID() {
        NeuroID.clientKey = nil

        let (started, id) = NeuroID.startSession()

        assert(!started)
        assert(id == "")
        assert(!NeuroID._isSDKStarted)
        assert(NeuroID.sendCollectionWorkItem == nil) // In real world it would != nil but because of tests we don't want to trigger a re-occuring event
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
        NeuroID.sendCollectionWorkItem = nil

        NeuroID.resumeCollection()

        assert(NeuroID._isSDKStarted)
        assert(NeuroID.sendCollectionWorkItem != nil)
    }

    func test_stopSession() {
        NeuroID._isSDKStarted = true
        NeuroID.sendCollectionWorkItem = DispatchWorkItem {}

        NeuroID.userID = "myUserID"
        NeuroID.registeredUserID = "myRegisteredUserID"

        let stopped = NeuroID.stopSession()

        assert(!NeuroID._isSDKStarted)
        assert(NeuroID.sendCollectionWorkItem == nil)

        assert(NeuroID.userID == nil)
        assert(NeuroID.registeredUserID == "")
    }
}

class NIDFormTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"

    let sessionIdKey = Constants.storageSessionIDKey.rawValue
    let clientIdKey = Constants.storageClientIDKey.rawValue

    func clearOutDataStore() {
        DataStore.removeSentEvents()
    }

    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey)
    }

    override func setUp() {
        let _ = NeuroID.start()
    }

    override func tearDown() {
        NeuroID.stop()

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
        NeuroID.configure(clientKey: clientKey)
    }

    override func setUp() {
        let _ = NeuroID.start()
    }

    override func tearDown() {
        NeuroID.stop()

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

    let userIdKey = Constants.storageUserIDKey.rawValue

    func clearOutDataStore() {
        DataStore.removeSentEvents()
        let _ = DataStore.getAndRemoveAllQueuedEvents()
    }

    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey)
    }

    override func setUp() {
        let _ = NeuroID.start()
    }

    override func tearDown() {
        NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    func assertStoredEventTypeAndCount(type: String, count: Int) {
        let allEvents = DataStore.getAllEvents()
        let validEvent = allEvents.filter { $0.type == type }

        assert(validEvent.count == count)
        assert(validEvent[0].type == type)
    }

    func assertQueuedEventTypeAndCount(type: String, count: Int) {
        let allEvents = DataStore.queuedEvents
        let validEvent = allEvents.filter { $0.type == type }

        assert(validEvent.count == count)
        assert(validEvent[0].type == type)
    }

    func test_validatedUserID_valid_id() {
        let validUserIds = [
            "123",
            "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789",
            "a-A_1.0",
        ]

        for userId in validUserIds {
            let userNameSet = NeuroID.validateUserID(userId)
            assert(userNameSet == true)
        }
    }

    func test_validatedUserID_invalid_id() {
        let invalidUserIds = [
            "",
            "1",
            "12",
            "to_long_789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789",
            "this_is_way_to_long_0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789",
            "invalid characters",
            "invalid*ch@racters",
        ]

        for userId in invalidUserIds {
            let userNameSet = NeuroID.validateUserID(userId)
            assert(userNameSet == false)
        }
    }

    func test_setGenericUserID_valid_id_started() {
        NeuroID._isSDKStarted = true

        let expectedValue = "myTestUserID"
        let result = NeuroID.setGenericUserID(
            userId: expectedValue,
            type: .userID
        ) { res in
            res
        }

        assert(result == true)
        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assert(DataStore.queuedEvents.count == 0)
    }

    func test_setGenericUserID_valid_id_queued() {
        NeuroID._isSDKStarted = false
        clearOutDataStore()

        let expectedValue = "myTestUserID"
        let result = NeuroID.setGenericUserID(
            userId: expectedValue,
            type: .userID
        ) { res in
            res
        }

        assert(result == true)
        assert(DataStore.events.count == 0)
        assertQueuedEventTypeAndCount(type: "SET_USER_ID", count: 1)
    }

    func test_setGenericUserID_valid_registered_id_started() {
        NeuroID._isSDKStarted = true

        let expectedValue = "myTestUserID"
        let result = NeuroID.setGenericUserID(
            userId: expectedValue,
            type: .registeredUserID
        ) { res in
            res
        }

        assert(result == true)
        assertStoredEventTypeAndCount(type: "REGISTERED_USER_ID", count: 1)
        assert(DataStore.queuedEvents.count == 0)
    }

    func test_setGenericUserID_valid_registered_id_queued() {
        NeuroID._isSDKStarted = false
        clearOutDataStore()

        let expectedValue = "myTestUserID"
        let result = NeuroID.setGenericUserID(
            userId: expectedValue,
            type: .registeredUserID
        ) { res in
            res
        }

        assert(result == true)
        assert(DataStore.events.count == 0)
        assertQueuedEventTypeAndCount(type: "REGISTERED_USER_ID", count: 1)
    }

    func test_setUserID_started() {
        UserDefaults.standard.removeObject(forKey: userIdKey)

        let expectedValue = "test_uid"

        let fnSuccess = NeuroID.setUserID(expectedValue)

        let storedValue = UserDefaults.standard.string(forKey: userIdKey)

        assert(fnSuccess)
        assert(NeuroID.userID == expectedValue)
        assert(storedValue == nil)

        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 1)
        assert(DataStore.queuedEvents.count == 0)
    }

    func test_setUserID_pre_start() {
        NeuroID.stop()
        UserDefaults.standard.removeObject(forKey: userIdKey)

        let expectedValue = "test_uid"

        let fnSuccess = NeuroID.setUserID(expectedValue)

        let storedValue = UserDefaults.standard.string(forKey: userIdKey)

        assert(fnSuccess == true)
        assert(NeuroID.userID == expectedValue)
        assert(storedValue == nil)

        assert(DataStore.events.count == 0)
        assertQueuedEventTypeAndCount(type: "SET_USER_ID", count: 1)
    }

    func test_getUserID_objectLevel() {
        UserDefaults.standard.removeObject(forKey: userIdKey)

        let expectedValue = "test_uid"

        NeuroID.userID = expectedValue

        let value = NeuroID.getUserID()

        assert(NeuroID.userID == expectedValue)
        assert(value == expectedValue)
    }

    func test_getUserID_dataStore() {
        let expectedValue = "test_uid"
        UserDefaults.standard.set(expectedValue, forKey: userIdKey)

        NeuroID.userID = nil

        let value = NeuroID.getUserID()

        assert(value == "")
        assert(NeuroID.userID != expectedValue)
    }

    func test_getRegisteredUserID_objectLevel() {
        UserDefaults.standard.removeObject(forKey: userIdKey)

        let expectedValue = "test_uid"

        NeuroID.registeredUserID = expectedValue

        let value = NeuroID.getRegisteredUserID()

        assert(NeuroID.registeredUserID == expectedValue)
        assert(value == expectedValue)
    }

    func test_setRegisteredUserID_started() {
        UserDefaults.standard.removeObject(forKey: userIdKey)

        let expectedValue = "test_ruid"

        let fnSuccess = NeuroID.setRegisteredUserID(expectedValue)

        let storedValue = UserDefaults.standard.string(forKey: userIdKey)

        assert(fnSuccess == true)
        assert(NeuroID.registeredUserID == expectedValue)
        assert(storedValue == nil)

        assertStoredEventTypeAndCount(type: "REGISTERED_USER_ID", count: 1)
        assert(DataStore.queuedEvents.count == 0)
    }

    func test_setRegisteredUserID_pre_start() {
        NeuroID.stop()
        UserDefaults.standard.removeObject(forKey: userIdKey)

        let expectedValue = "test_ruid"

        let fnSuccess = NeuroID.setRegisteredUserID(expectedValue)

        let storedValue = UserDefaults.standard.string(forKey: userIdKey)

        assert(fnSuccess == true)
        assert(NeuroID.registeredUserID == expectedValue)
        assert(storedValue == nil)

        assert(DataStore.events.count == 0)
        assertQueuedEventTypeAndCount(type: "REGISTERED_USER_ID", count: 1)
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
    }

    func test_getClientKey() {
        NeuroID.configure(clientKey: clientKey)
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
}

class NIDSendTests: XCTestCase {
    func test_getCollectionEndpointURL() {
        let expectedValue = "https://receiver.neuroid.cloud/c"

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
    }

    let configOptionsTrue = [RNConfigOptions.usingReactNavigation.rawValue: true]
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
        NeuroID.configure(
            clientKey: "test",
            rnOptions: configOptionsTrue
        )

        assertConfigureTests(defaultValue: false, expectedValue: true)
    }

    func test_configure_usingReactNavigation_false() {
        assert(!NeuroID.isRN)
        NeuroID.configure(
            clientKey: "test",
            rnOptions: configOptionsFalse
        )

        assertConfigureTests(defaultValue: true, expectedValue: false)
    }

    func test_configure_invalid_key() {
        assert(!NeuroID.isRN)
        NeuroID.configure(
            clientKey: "test",
            rnOptions: configOptionsInvalid
        )

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
