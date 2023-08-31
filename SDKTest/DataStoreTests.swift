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

    override func setUpWithError() throws {
        UserDefaults.standard.setValue(nil, forKey: eventsKey)
        NeuroID.configure(clientKey: clientKey)
        NeuroID.stop()
        NeuroID.start()
        let _ = DataStore.getAndRemoveAllEvents()
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
        NeuroID.stop()

        let nidE = NIDEvent(
            type: .radioChange
        )

        DataStore.insertEvent(screen: screenName, event: nidE)
        assert(DataStore.events.count == 0)
    }

    func test_insertEvent_RNScreen() {
        let nidE = NIDEvent(
            type: .radioChange
        )
        nidE.url = "RNScreensNavigationController"

        DataStore.insertEvent(screen: screenName, event: nidE)
        assert(DataStore.events.count == 0)
    }

    func test_insertEvent_excludedView_tg() {
        NeuroID.excludeViewByTestID(excludedView: "exclude_test_id")

        let nidE = NIDEvent(
            type: .radioChange
        )
        nidE.tg = [
            "tgs": TargetValue.string("exclude_test_id"),
        ]

        DataStore.insertEvent(screen: screenName, event: nidE)
        assert(DataStore.events.count == 0)
    }

    func test_insertEvent_excludedView_tgs() {
        NeuroID.excludeViewByTestID(excludedView: "exclude_test_id")

        let nidE = NIDEvent(
            type: .radioChange
        )

        nidE.tgs = "exclude_test_id"

        DataStore.insertEvent(screen: screenName, event: nidE)
        assert(DataStore.events.count == 0)
    }

    func test_insertEvent_excludedView_en() {
        NeuroID.excludeViewByTestID(excludedView: "exclude_test_id")

        let nidE = NIDEvent(
            type: .radioChange
        )

        nidE.en = "exclude_test_id"

        DataStore.insertEvent(screen: screenName, event: nidE)
        assert(DataStore.events.count == 0)
    }

    func test_insertEvent_success() {
        let screen = "DS_TEST_SCREEN"
        NeuroID.currentScreenName = screen

        let nidE = NIDEvent(
            type: .radioChange
        )
        assert(nidE.url == nil)

        DataStore.insertEvent(screen: screenName, event: nidE)
        assert(DataStore.events.count == 1)
        assert(DataStore.events[0].url == "ios://\(screen)")
    }

    func test_getAllEvents() {
        assert(DataStore.events.count == 0)

        DataStore.events = [
            NIDEvent(
                type: .radioChange
            ),
        ]

        let retrievedEvents = DataStore.getAllEvents()

        assert(retrievedEvents.count == 1)
    }

    func test_getAndRemoveAllEvents() {
        assert(DataStore.events.count == 0)

        DataStore.events = [
            NIDEvent(
                type: .radioChange
            ),
        ]

        let retrievedEvents = DataStore.getAndRemoveAllEvents()

        assert(retrievedEvents.count == 1)
        assert(DataStore.events.count == 0)
    }

    func test_getUserDefaultKeyBool() {
        let key = "MyBoolKey"
        UserDefaults.standard.set(false, forKey: key)

        let value = getUserDefaultKeyBool(key)
        assert(value == false)
    }

    func test_getUserDefaultKeyBool_true() {
        let key = "MyBoolKey"
        UserDefaults.standard.set(true, forKey: key)

        let value = getUserDefaultKeyBool(key)
        assert(value == true)
    }

    func test_getUserDefaultKeyBool_nil() {
        let key = "MyBoolKey"
        UserDefaults.standard.set(nil, forKey: key)

        let value = getUserDefaultKeyBool(key)
        assert(value == false)
    }

    func test_getUserDefaultKeyString() {
        let key = "MyStringKey"
        UserDefaults.standard.set("", forKey: key)

        let value = getUserDefaultKeyString(key)
        assert(value == "")
    }

    func test_getUserDefaultKeyString_value() {
        let key = "MyStringKey"
        UserDefaults.standard.set("test", forKey: key)

        let value = getUserDefaultKeyString(key)
        assert(value == "test")
    }

    func test_getUserDefaultKeyString_nil() {
        let key = "MyStringKey"
        UserDefaults.standard.set(nil, forKey: key)

        let value = getUserDefaultKeyString(key)
        assert(value == nil)
    }

    func test_setUserDefaultKey_string() {
        let key = "MyStringKey"

        setUserDefaultKey(key, value: "test")

        let value = UserDefaults.standard.string(forKey: key)
        assert(value == "test")
    }

    func test_setUserDefaultKey_string_nil() {
        let key = "MyStringKey"

        setUserDefaultKey(key, value: nil)

        let value = UserDefaults.standard.string(forKey: key)
        assert(value == nil)
    }

    func test_setUserDefaultKey_bool() {
        let key = "MyStringKey"

        setUserDefaultKey(key, value: true)

        let value = UserDefaults.standard.bool(forKey: key)
        assert(value == true)
    }

}
