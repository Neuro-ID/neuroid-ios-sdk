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
    let tabIdKey = Constants.storageTabIdKey.rawValue

    func clearOutDataStore() {
        DataStore.removeSentEvents()
    }

    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey)
    }

    override func setUp() {
        try? NeuroID.start()
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
        NeuroID._isSDKStarted = false
        NeuroID.clientKey = nil

        // pre tests
        assert(!NeuroID.isSDKStarted)
        assert(NeuroID.clientKey == nil)

        // action
        do {
            try NeuroID.start()
        } catch {
            assert(error.localizedDescription == "The Client Key is missing")
        }
        // post action test
        assert(!NeuroID.isSDKStarted)
    }

    func test_start_success() {
        NeuroID._isSDKStarted = false

        // pre tests
        assert(!NeuroID.isSDKStarted)

        // action
        try? NeuroID.start()

        // post action test
        assert(NeuroID.isSDKStarted)
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
        try? NeuroID.start()
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

    let sessionIdKey = Constants.storageSiteIdKey.rawValue
    let clientIdKey = Constants.storageClientIdKey.rawValue

    func clearOutDataStore() {
        DataStore.removeSentEvents()
    }

    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey)
    }

    override func setUp() {
        try? NeuroID.start()
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

    func test_setScreenName_getScreenName_withSpace() {
        clearOutDataStore()
        let expectedValue = "test Screen"
        try? NeuroID.setScreenName(screen: expectedValue)

        let value = NeuroID.getScreenName()

        assert(value == "test%20Screen")

        assertStoredEventTypeAndCount(type: "MOBILE_METADATA_IOS", count: 1)
    }

    func test_clearSession() {
        UserDefaults.standard.set("session", forKey: sessionIdKey)
        UserDefaults.standard.set("client", forKey: clientIdKey)

        NeuroID.clearSession()

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

        assertStoredEventTypeAndCount(type: "MOBILE_METADATA_IOS", count: 1)
    }
}

class NIDFormTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"

    let sessionIdKey = Constants.storageSiteIdKey.rawValue
    let clientIdKey = Constants.storageClientIdKey.rawValue

    func clearOutDataStore() {
        DataStore.removeSentEvents()
    }

    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey)
    }

    override func setUp() {
        try? NeuroID.start()
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
        try? NeuroID.start()
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
        try? NeuroID.setScreenName(screen: expectedValue)

        let value = NeuroID.getScreenName()

        assert(value == expectedValue)

        assertStoredEventTypeAndCount(type: "MOBILE_METADATA_IOS", count: 1)
    }

    func test_setScreenName_getScreenName_withSpace() {
        clearOutDataStore()
        let expectedValue = "test Screen"
        try? NeuroID.setScreenName(screen: expectedValue)

        let value = NeuroID.getScreenName()

        assert(value == "test%20Screen")

        assertStoredEventTypeAndCount(type: "MOBILE_METADATA_IOS", count: 1)
    }
}

class NIDUserTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"

    let userIdKey = Constants.storageUserIdKey.rawValue

    func clearOutDataStore() {
        DataStore.removeSentEvents()
    }

    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey)
    }

    override func setUp() {
        try? NeuroID.start()
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

    func test_setUserID() {
        UserDefaults.standard.removeObject(forKey: userIdKey)

        let expectedValue = "test_uid"

        try? NeuroID.setUserID(expectedValue)

        let storedValue = UserDefaults.standard.string(forKey: userIdKey)

        assert(NeuroID.userId == expectedValue)
        assert(storedValue == expectedValue)

        assertStoredEventTypeAndCount(type: "SET_USER_ID", count: 1)
    }

    func test_setUserID_valid_id() {
        let validUserIds = [
            "123",
            "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789",
            "a-A_1.0",
        ]

        for userId in validUserIds {
            XCTAssertNoThrow(try NeuroID.setUserID(userId))
        }
    }

    func test_setUserID_invalid_id() {
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
            XCTAssertThrowsError(try NeuroID.setUserID(userId)) { error in
                // could not get checks against error of type NIDError and instance of invalidUserID to work hence the following hack
                assert(String(describing: error) == String(describing: NIDError.invalidUserID))
            }
        }
    }

    func test_getUserID_objectLevel() {
        UserDefaults.standard.removeObject(forKey: userIdKey)

        let expectedValue = "test_uid"

        NeuroID.userId = expectedValue

        let value = NeuroID.getUserID()

        assert(NeuroID.userId == expectedValue)
        assert(value == expectedValue)
    }

    func test_getUserID_dataStore() {
        let expectedValue = "test_uid"
        UserDefaults.standard.set(expectedValue, forKey: userIdKey)

        NeuroID.userId = nil

        let value = NeuroID.getUserID()

        assert(value == expectedValue)
        assert(NeuroID.userId != expectedValue)
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
    let cidKey = Constants.storageClientIdKey.rawValue

    func test_getClientID() {
        UserDefaults.standard.setValue("test-cid", forKey: cidKey)
        NeuroID.clientId = nil
        let value = NeuroID.getClientID()

        assert(value == "test-cid")
    }

    func test_getClientId_existing() {
        let expectedValue = "test-cid"

        NeuroID.clientId = expectedValue
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

        assert(NeuroID.siteId == "test_site")
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
