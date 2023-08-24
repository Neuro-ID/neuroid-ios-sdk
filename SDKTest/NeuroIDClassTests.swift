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
    let userId = "form_mobilesandbox"

    // Keys for storage:
    let localStorageNIDStopAll = Constants.storageLocalNIDStopAllKey.rawValue
    let clientKeyKey = Constants.storageClientKey.rawValue
    let clientIdKey = Constants.storageClientIdKey.rawValue
    let sessionIdKey = Constants.storageSiteIdKey.rawValue
    let tabIdKey = Constants.storageTabIdKey.rawValue
    let userIdKey = Constants.storageUserIdKey.rawValue

    func clearOutDataStore() {
        DataStore.removeSentEvents()
    }

    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey)
    }

    override func setUp() {
        NeuroID.start()
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

    func test_configure() {
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
    }

    func test_configure_endpoint() {
        clearOutDataStore()
        // remove things configured in setup
        NeuroID.clientKey = nil
        UserDefaults.standard.setValue(nil, forKey: clientKeyKey)
        UserDefaults.standard.setValue("testTabId", forKey: tabIdKey)

        NeuroID.configure(clientKey: clientKey, collectorEndPoint: "testEndpoint")

        let clientKeyValue = UserDefaults.standard.string(forKey: clientKeyKey)
        assert(clientKeyValue == clientKey)

        let tabIdValue = UserDefaults.standard.string(forKey: tabIdKey)
        assert(tabIdValue == nil)

        assert(NeuroID.collectorURLFromConfig == "testEndpoint")

        assertStoredEventCount(type: "CREATE_SESSION", count: 0)
    }

    func test_enableLogging_true() {
        NeuroID.enableLogging(true)

        assert(NeuroID.logVisible)
    }

    func test_enableLogging_false() {
        NeuroID.enableLogging(false)

        assert(!NeuroID.logVisible)
    }

    func test_getClientID() {
        UserDefaults.standard.setValue("test-cid", forKey: Constants.storageClientIdKey.rawValue)
        NeuroID.clientId = nil
        let value = NeuroID.getClientID()

        assert(value == "test-cid")
    }

    func test_getEnvironment() {
        assert(NeuroID.getEnvironment() == "TEST")
    }

    func test_setEnvironmentProduction_true() {
        NeuroID.setEnvironmentProduction(true)

        assert(NeuroID.getEnvironment() == "LIVE")
    }

    func test_setEnvironmentProduction_false() {
        NeuroID.setEnvironmentProduction(false)

        assert(NeuroID.getEnvironment() == "TEST")
    }

    func test_setSiteId() {
        NeuroID.setSiteId(siteId: "test_site")

        assert(NeuroID.siteId == "test_site")
    }

    func test_stop() {
        NeuroID.start()
        let stopped = UserDefaults.standard.bool(forKey: localStorageNIDStopAll)
        assert(stopped == false)

        NeuroID.stop()

        let stopped2 = UserDefaults.standard.bool(forKey: localStorageNIDStopAll)
        assert(stopped2 == true)
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

    func test_setScreenName_getScreenName() {
        let expectedValue = "testScreen"
        try? NeuroID.setScreenName(screen: expectedValue)

        let value = NeuroID.getScreenName()

        assert(value == expectedValue)
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

    func test_createSession() {
        clearOutDataStore()
        DataStore.removeSentEvents()

        NeuroID.createSession()

        assertStoredEventTypeAndCount(type: "CREATE_SESSION", count: 1)
    }

    func test_closeSession() {
        clearOutDataStore()
        do {
            try NeuroID.closeSession()
        }
        catch {
            print("Threw on Close Session")
        }

        assertStoredEventTypeAndCount(type: "CLOSE_SESSION", count: 1)
    }

    func test_start() {
        UserDefaults.standard.set(true, forKey: localStorageNIDStopAll)
        NeuroID.isSDKStarted = false

        // pre tests
        assert(!NeuroID.isSDKStarted)

        let NIDStopTracking = UserDefaults.standard.bool(forKey: localStorageNIDStopAll)
        assert(NIDStopTracking)

        // action
        NeuroID.start()

        // post action test
        assert(NeuroID.isSDKStarted)

        let NIDStopTrackingAfter = UserDefaults.standard.bool(forKey: localStorageNIDStopAll)
        assert(!NIDStopTrackingAfter)
    }

    func test_isStopped() {
        UserDefaults.standard.set(true, forKey: localStorageNIDStopAll)

        let NIDStopTracking = NeuroID.isStopped()
        assert(NIDStopTracking)
    }

    func test_isStopped_false() {
        UserDefaults.standard.set(false, forKey: localStorageNIDStopAll)

        let NIDStopTracking = NeuroID.isStopped()
        assert(!NIDStopTracking)
    }

    func test_formSubmit() {
        clearOutDataStore()
        let event = NeuroID.formSubmit()

        assertStoredEventTypeAndCount(type: "APPLICATION_SUBMIT", count: 1)
    }

    func test_formSubmitFailure() {
        clearOutDataStore()
        let event = NeuroID.formSubmitFailure()

        assertStoredEventTypeAndCount(type: "APPLICATION_SUBMIT_FAILURE", count: 1)
    }

    func test_formSubmitSuccess() {
        clearOutDataStore()
        let event = NeuroID.formSubmitSuccess()

        assertStoredEventTypeAndCount(type: "APPLICATION_SUBMIT_SUCCESS", count: 1)
    }

    func test_setCustomVariable() {
        clearOutDataStore()
        let event = NeuroID.setCustomVariable(key: "t", v: "v")

        assertStoredEventTypeAndCount(type: "SET_VARIABLE", count: 1)
    }

    func test_getCollectionEndpointURL() {
        let expectedValue = "https://receiver.neuroid.cloud/c"

        let value = NeuroID.getCollectionEndpointURL()
        assert(value == expectedValue)
    }

    func test_getClientKeyFromLocalStorage() {
        let expectedValue = "testClientKey"

        UserDefaults.standard.setValue(expectedValue, forKey: clientKeyKey)

        let value = NeuroID.getClientKeyFromLocalStorage()
        assert(value == expectedValue)
    }

    func test_manuallyRegisterTarget_valid_type() {
        clearOutDataStore()
        let uiView = UITextField()

        NeuroID.manuallyRegisterTarget(view: uiView)

        assertStoredEventTypeAndCount(type: "REGISTER_TARGET", count: 1)
    }

    func test_manuallyRegisterTarget_invalid_type() {
        clearOutDataStore()
        let uiView = UIView()

        NeuroID.manuallyRegisterTarget(view: uiView)

        assertDataStoreCount(count: 0)
    }

    func test_manuallyRegisterRNTarget() {
        clearOutDataStore()

        let event = NeuroID.manuallyRegisterRNTarget(id: "test", className: "testClassName", screenName: "testScreenName", placeHolder: "testPlaceholder")

        assert(event.tgs == "test")
        assert(event.et == "testClassName")

        assertStoredEventTypeAndCount(type: "REGISTER_TARGET", count: 1)
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

    func test_saveEventToLocalDataStore() {
        let event = NIDEvent(type: NIDEventName.heartbeat)

        NeuroID.saveEventToLocalDataStore(event)

        assertStoredEventTypeAndCount(type: "HEARTBEAT", count: 1)
    }

    func test_cleanUpForTesting() {
        let expectedValue = "dummyKey"
        NeuroID.clientKey = expectedValue

        assert(NeuroID.clientKey == expectedValue)

        NeuroID.cleanUpForTesting()

        assert(NeuroID.clientKey != expectedValue)
        assert(NeuroID.clientKey == nil)
    }

    func test_getSDKVersion() {
        let expectedValue = ParamsCreator.getSDKVersion()

        let value = NeuroID.getSDKVersion()

        assert(value == expectedValue)
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
