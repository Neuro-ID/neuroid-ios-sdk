//
//  DataStoreTests.swift
//  NeuroID
//
//  Created by Clayton Selby on 10/19/21.
//

@testable import NeuroID
import XCTest

class DataStoreTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"

    let eventsKey = "test_events_stored"
    let screenName = "test_screen_name"

    let testStoreKey = "test_stored_key"

    let nidEvent = NIDEvent(
        type: .radioChange
    )

    let excludeId = "exclude_test_id"

    var dataStore = DataStore()

    override func setUpWithError() throws {
        UserDefaults.standard.setValue(nil, forKey: eventsKey)
        let configuration = NeuroID.Configuration(clientKey: clientKey, isAdvancedDevice: false)
        _ = NeuroID.configure(configuration)
        _ = NeuroID.stop()
        NeuroID.shared._isSDKStarted = true

        dataStore = DataStore()
    }

    override func tearDownWithError() throws {
        _ = NeuroID.stop()
    }

    func testEncodeAndDecode() throws {
        let nidE = NIDEvent(
            type: .radioChange,
            tg: ["name": TargetValue.string("john")]
        )

        let encoder = JSONEncoder()

        do {
            let jsonData = try encoder.encode([nidE])
            UserDefaults.standard.setValue(jsonData, forKey: eventsKey)
            let existingEvents = UserDefaults.standard.object(forKey: eventsKey)
            let parsedEvents = try JSONDecoder().decode([NIDEvent].self, from: existingEvents as! Data)

            assert(parsedEvents.count == 1)
            assert(parsedEvents[0].type == "RADIO_CHANGE")
            assert(parsedEvents[0].tg?["name"]?.toString() == "john")
        } catch {
            assertionFailure("Failed to Encode/Decode: \(String(describing: error))")
        }
    }

    func test_insertCleanedEvent_queued() {
        let nidE = nidEvent

        dataStore.insertCleanedEvent(event: nidE, storeType: "queue")
        assert(dataStore.events.count == 0)
        assert(dataStore.queuedEvents.count == 1)
    }

    func test_insertCleanedEvent_event() {
        let nidE = nidEvent

        dataStore.insertCleanedEvent(event: nidE, storeType: "event")
        assert(dataStore.events.count == 1)
        assert(dataStore.queuedEvents.count == 0)
    }

    func test_getAllEvents() {
        assert(dataStore.events.count == 0)

        dataStore.events = [
            nidEvent
        ]

        let retrievedEvents = dataStore.getAllEvents()

        assert(retrievedEvents.count == 1)
    }

    func test_getAndRemoveAllEvents() {
        assert(dataStore.events.count == 0)

        dataStore.events = [
            nidEvent
        ]

        let retrievedEvents = dataStore.getAndRemoveAllEvents()

        assert(retrievedEvents.count == 1)
        assert(dataStore.events.count == 0)
    }

    func test_getAndRemoveAllQueuedEvents() {
        assert(dataStore.queuedEvents.count == 0)

        dataStore.queuedEvents = [
            nidEvent
        ]

        let retrievedEvents = dataStore.getAndRemoveAllQueuedEvents()

        assert(retrievedEvents.count == 1)
        assert(dataStore.queuedEvents.count == 0)
    }

    func test_getUserDefaultKeyBool() {
        UserDefaults.standard.set(false, forKey: testStoreKey)

        let value = getUserDefaultKeyBool(testStoreKey)
        assert(value == false)
    }

    func test_getUserDefaultKeyBool_true() {
        UserDefaults.standard.set(true, forKey: testStoreKey)

        let value = getUserDefaultKeyBool(testStoreKey)
        assert(value == true)
    }

    func test_getUserDefaultKeyBool_nil() {
        UserDefaults.standard.set(nil, forKey: testStoreKey)

        let value = getUserDefaultKeyBool(testStoreKey)
        assert(value == false)
    }

    func test_getUserDefaultKeyString() {
        UserDefaults.standard.set("", forKey: testStoreKey)

        let value = getUserDefaultKeyString(testStoreKey)
        assert(value == "")
    }

    func test_getUserDefaultKeyString_value() {
        UserDefaults.standard.set("test", forKey: testStoreKey)

        let value = getUserDefaultKeyString(testStoreKey)
        assert(value == "test")
    }

    func test_getUserDefaultKeyString_nil() {
        UserDefaults.standard.set(nil, forKey: testStoreKey)

        let value = getUserDefaultKeyString(testStoreKey)
        assert(value == nil)
    }

    func test_getUserDefaultKeyDict_value() {
        UserDefaults.standard.set(["foo": "bar"], forKey: testStoreKey)

        let value = getUserDefaultKeyDict(testStoreKey)
        if let myV = value {
            assert(myV["foo"] != nil)
        } else {
            assertionFailure("Dictionary Missing")
        }
    }

    func test_getUserDefaultKeyDict_nil() {
        UserDefaults.standard.set(nil, forKey: testStoreKey)

        let value = getUserDefaultKeyDict(testStoreKey)
        assert(value == nil)
    }

    func test_setUserDefaultKey_string() {
        setUserDefaultKey(testStoreKey, value: "test")

        let value = UserDefaults.standard.string(forKey: testStoreKey)
        assert(value == "test")
    }

    func test_setUserDefaultKey_string_nil() {
        setUserDefaultKey(testStoreKey, value: nil)

        let value = UserDefaults.standard.string(forKey: testStoreKey)
        assert(value == nil)
    }

    func test_setUserDefaultKey_bool() {
        setUserDefaultKey(testStoreKey, value: true)

        let value = UserDefaults.standard.bool(forKey: testStoreKey)
        assert(value == true)
    }

    func test_getUserDefaultKeyDouble_no_value() {
        UserDefaults.standard.removeObject(forKey: "test_key")
        assert(getUserDefaultKeyDouble("test_key") == 0)
    }

    func test_getUserDefaultKeyDouble_valid_value() {
        setUserDefaultKey("test_key", value: 15.0)
        assert(getUserDefaultKeyDouble("test_key") == 15.0)
    }
}
