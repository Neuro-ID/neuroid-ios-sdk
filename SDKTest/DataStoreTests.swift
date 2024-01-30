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

    override func setUpWithError() throws {
        NeuroID.captureGyroCadence = false
        UserDefaults.standard.setValue(nil, forKey: eventsKey)
        NeuroID.configure(clientKey: clientKey)
        NeuroID.stop()
        let _ = NeuroID.start()
        let _ = DataStore.getAndRemoveAllEvents()
        let _ = DataStore.getAndRemoveAllQueuedEvents()
    }

    override func tearDownWithError() throws {
        NeuroID.stop()
    }

    func testEncodeAndDecode() throws {
        let nidE = NIDEvent(
            type: .radioChange,
            tg: ["name": TargetValue.string("john")],
            view: UIView()
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

    func test_insertEvent_stoppedSDK() {
        _ = NeuroID.stop()

        DataStore.insertEvent(screen: screenName, event: nidEvent)
        assert(DataStore.events.count == 0)
    }

    func test_insertEvent_success() {
        let screen = "DS_TEST_SCREEN"
        NeuroID.currentScreenName = screen

        let nidE = nidEvent
        assert(nidE.url == nil)

        DataStore.insertEvent(screen: screenName, event: nidE)
        assert(DataStore.events.count == 1)
        assert(DataStore.events[0].url == "ios://\(screen)")
    }

    func test_insertQueuedEvent_success() {
        let screen = "DS_TEST_SCREEN"
        NeuroID.currentScreenName = screen

        let nidE = nidEvent
        assert(nidE.url == nil)

        DataStore.insertQueuedEvent(screen: screenName, event: nidE)
        assert(DataStore.events.count == 0)
        assert(DataStore.queuedEvents.count == 1)
        assert(DataStore.queuedEvents[0].url == "ios://\(screen)")
    }

    func test_cleanAndStoreEvent_RNScreen() {
        let nidE = nidEvent
        nidE.url = "RNScreensNavigationController"

        DataStore.cleanAndStoreEvent(screen: screenName, event: nidE, storeType: "")
        assert(DataStore.events.count == 0)
    }

    func test_cleanAndStoreEvent_excludedView_tg() {
        NeuroID.excludeViewByTestID(excludedView: excludeId)

        let nidE = nidEvent
        nidE.tg = [
            "tgs": TargetValue.string(excludeId)
        ]

        DataStore.cleanAndStoreEvent(screen: screenName, event: nidE, storeType: "")
        assert(DataStore.events.count == 0)
    }

    func test_cleanAndStoreEvent_excludedView_tgs() {
        NeuroID.excludeViewByTestID(excludedView: excludeId)

        let nidE = nidEvent

        nidE.tgs = excludeId

        DataStore.cleanAndStoreEvent(screen: screenName, event: nidE, storeType: "")
        assert(DataStore.events.count == 0)
    }

    func test_cleanAndStoreEvent_excludedView_en() {
        NeuroID.excludeViewByTestID(excludedView: excludeId)

        let nidE = nidEvent

        nidE.en = excludeId

        DataStore.cleanAndStoreEvent(screen: screenName, event: nidE, storeType: "")
        assert(DataStore.events.count == 0)
    }

    func test_insertCleanedEvent_queued() {
        let nidE = nidEvent

        DataStore.insertCleanedEvent(event: nidE, storeType: "queue")
        assert(DataStore.events.count == 0)
        assert(DataStore.queuedEvents.count == 1)
    }

    func test_insertCleanedEvent_event() {
        let nidE = nidEvent

        DataStore.insertCleanedEvent(event: nidE, storeType: "event")
        assert(DataStore.events.count == 1)
        assert(DataStore.queuedEvents.count == 0)
    }

    func test_getAllEvents() {
        assert(DataStore.events.count == 0)

        DataStore.events = [
            nidEvent
        ]

        let retrievedEvents = DataStore.getAllEvents()

        assert(retrievedEvents.count == 1)
    }

    func test_getAndRemoveAllEvents() {
        assert(DataStore.events.count == 0)

        DataStore.events = [
            nidEvent
        ]

        let retrievedEvents = DataStore.getAndRemoveAllEvents()

        assert(retrievedEvents.count == 1)
        assert(DataStore.events.count == 0)
    }

    func test_getAndRemoveAllQueuedEvents() {
        assert(DataStore.queuedEvents.count == 0)

        DataStore.queuedEvents = [
            nidEvent
        ]

        let retrievedEvents = DataStore.getAndRemoveAllQueuedEvents()

        assert(retrievedEvents.count == 1)
        assert(DataStore.queuedEvents.count == 0)
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
}
