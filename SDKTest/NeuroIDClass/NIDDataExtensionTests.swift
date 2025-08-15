//
//  NIDDataExtensionTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 1/21/25.
//

@testable import NeuroID
import XCTest

class NIDDataExtensionTests: BaseTestClass {
    let eventsKey = "test_events_stored"
    let screenName = "test_screen_name"

    let nidEvent = NIDEvent(
        type: .radioChange
    )

    let excludeId = "exclude_test_id"

    override func setUpWithError() throws {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
        NeuroID.shared.datastore = dataStore
    }

    override func setUp() {
        UserDefaults.standard.removeObject(forKey: Constants.storageAdvancedDeviceKey.rawValue)
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    func test_saveEventToLocalDataStore_stoppedSDK() {
        _ = NeuroID.stop()

        NeuroID.saveEventToLocalDataStore(nidEvent, screen: screenName)
        assert(dataStore.events.count == 0)
    }

    func test_saveEventToLocalDataStore_success() {
        let screen = "DS_TEST_SCREEN"
        NeuroID.currentScreenName = screen
        NeuroID.shared.datastore = dataStore

        NeuroID._isSDKStarted = true

        let nidE = nidEvent
        assert(nidE.url == nil)

        NeuroID.saveEventToLocalDataStore(nidE, screen: screenName)
        assert(dataStore.events.count == 1)
        assert(dataStore.events[0].url == "ios://\(screen)")
    }

    func test_saveQueuedEventToLocalDataStore_success() {
        let screen = "DS_TEST_SCREEN"
        NeuroID.currentScreenName = screen

        let nidE = nidEvent
        assert(nidE.url == nil)

        NeuroID.saveQueuedEventToLocalDataStore(nidE, screen: screenName)
        assert(dataStore.events.count == 0)
        assert(dataStore.queuedEvents.count == 1)
        assert(dataStore.queuedEvents[0].url == "ios://\(screen)")
    }

    func test_cleanAndStoreEvent_RNScreen() {
        let nidE = nidEvent
        nidE.url = "RNScreensNavigationController"

        NeuroID.cleanAndStoreEvent(screen: screenName, event: nidE, storeType: "")
        assert(dataStore.events.count == 0)
    }

    func test_cleanAndStoreEvent_excludedView_tg() {
        NeuroID.excludeViewByTestID(excludedView: excludeId)

        let nidE = nidEvent
        nidE.tg = [
            "tgs": TargetValue.string(excludeId)
        ]

        NeuroID.cleanAndStoreEvent(screen: screenName, event: nidE, storeType: "")
        assert(dataStore.events.count == 0)
    }

    func test_cleanAndStoreEvent_excludedView_tgs() {
        NeuroID.excludeViewByTestID(excludedView: excludeId)

        let nidE = nidEvent

        nidE.tgs = excludeId

        NeuroID.cleanAndStoreEvent(screen: screenName, event: nidE, storeType: "")
        assert(dataStore.events.count == 0)
    }

    func test_cleanAndStoreEvent_excludedView_en() {
        NeuroID.excludeViewByTestID(excludedView: excludeId)

        let nidE = nidEvent

        nidE.en = excludeId

        NeuroID.cleanAndStoreEvent(screen: screenName, event: nidE, storeType: "")
        assert(dataStore.events.count == 0)
    }
}
