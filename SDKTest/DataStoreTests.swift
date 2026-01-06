//
//  DataStoreTests.swift
//  NeuroID
//
//  Created by Clayton Selby on 10/19/21.
//

@testable import NeuroID
import Testing

@Suite("DataStore Tests")
class DataStoreTests {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"

    let eventsKey = "test_events_stored"
    let screenName = "test_screen_name"

    let testStoreKey = "test_stored_key"

    let nidEvent = NIDEvent(
        type: .radioChange
    )

    let excludeId = "exclude_test_id"

    var dataStore = DataStore(logger: NIDLog())

    init() {
        UserDefaults.standard.setValue(nil, forKey: eventsKey)
        let configuration = NeuroID.Configuration(clientKey: clientKey, isAdvancedDevice: false)
        _ = NeuroID.configure(configuration)
        _ = NeuroID.stop()
        NeuroID.shared._isSDKStarted = true

        dataStore = DataStore(logger: NIDLog())
    }

    deinit {
        _ = NeuroID.stop()
    }

    @Test func encodeAndDecode() throws {
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

            #expect(parsedEvents.count == 1)
            #expect(parsedEvents[0].type == "RADIO_CHANGE")
            #expect(parsedEvents[0].tg?["name"]?.toString() == "john")
        } catch {
            assertionFailure("Failed to Encode/Decode: \(String(describing: error))")
        }
    }

    @Test func insertCleanedEvent_queued() {
        let nidE = nidEvent

        dataStore.insertCleanedEvent(event: nidE, storeType: "queue")
        #expect(dataStore.events.count == 0)
        #expect(dataStore.queuedEvents.count == 1)
    }

    @Test func insertCleanedEvent_event() {
        let nidE = nidEvent

        dataStore.insertCleanedEvent(event: nidE, storeType: "event")
        #expect(dataStore.events.count == 1)
        #expect(dataStore.queuedEvents.count == 0)
    }

    @Test func getAllEvents() {
        #expect(dataStore.events.count == 0)

        dataStore.events = [
            nidEvent
        ]

        let retrievedEvents = dataStore.getAllEvents()

        #expect(retrievedEvents.count == 1)
    }

    @Test func getAndRemoveAllEvents() {
        #expect(dataStore.events.count == 0)

        dataStore.events = [
            nidEvent
        ]

        let retrievedEvents = dataStore.getAndRemoveAllEvents()

        #expect(retrievedEvents.count == 1)
        #expect(dataStore.events.count == 0)
    }

    @Test func getAndRemoveAllQueuedEvents() {
        #expect(dataStore.queuedEvents.count == 0)

        dataStore.queuedEvents = [
            nidEvent
        ]

        let retrievedEvents = dataStore.getAndRemoveAllQueuedEvents()

        #expect(retrievedEvents.count == 1)
        #expect(dataStore.queuedEvents.count == 0)
    }

    @Test(arguments: [true, false, nil]) func testGetUserDefaultKeyBool(input: Bool?) {
        UserDefaults.standard.set(input, forKey: testStoreKey)

        let value = getUserDefaultKeyBool(testStoreKey)
        #expect(value == input ?? false)
    }

    @Test(arguments: ["", "test", nil]) func testGetUserDefaultKeyString(input: String?) {
        UserDefaults.standard.set(input, forKey: testStoreKey)

        let value = getUserDefaultKeyString(testStoreKey)
        #expect(value == input)
    }

    @Test func getUserDefaultKeyDict_value() {
        UserDefaults.standard.set(["foo": "bar"], forKey: testStoreKey)

        let value = getUserDefaultKeyDict(testStoreKey)
        if let myV = value {
            #expect(myV["foo"] != nil)
        } else {
            assertionFailure("Dictionary Missing")
        }
    }

    @Test func getUserDefaultKeyDict_nil() {
        UserDefaults.standard.set(nil, forKey: testStoreKey)

        let value = getUserDefaultKeyDict(testStoreKey)
        #expect(value == nil)
    }

    @Test func setUserDefaultKey_string() {
        setUserDefaultKey(testStoreKey, value: "test")

        let value = UserDefaults.standard.string(forKey: testStoreKey)
        #expect(value == "test")
    }

    @Test func setUserDefaultKey_string_nil() {
        setUserDefaultKey(testStoreKey, value: nil)

        let value = UserDefaults.standard.string(forKey: testStoreKey)
        #expect(value == nil)
    }

    @Test func setUserDefaultKey_bool() {
        setUserDefaultKey(testStoreKey, value: true)

        let value = UserDefaults.standard.bool(forKey: testStoreKey)
        #expect(value == true)
    }

    @Test func getUserDefaultKeyDouble_no_value() {
        UserDefaults.standard.removeObject(forKey: "test_key")
        #expect(getUserDefaultKeyDouble("test_key") == 0)
    }

    @Test func getUserDefaultKeyDouble_valid_value() {
        setUserDefaultKey("test_key", value: 15.0)
        #expect(getUserDefaultKeyDouble("test_key") == 15.0)
    }
}
