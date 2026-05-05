//
//  NIDDataExtensionTests.swift
//  SDKTest
//

import Foundation
import Testing

@testable import NeuroID

@Suite(.serialized)
class NIDDataExtensionTests {

    var dataStore: DataStore
    var neuroID: NeuroIDCore

    let screenName = "test_screen_name"
    let excludeId = "exclude_test_id"

    let nidEvent = NIDEvent(
        type: .radioChange
    )

    init() {
        UserDefaults.standard.removeObject(forKey: Constants.storageAdvancedDeviceKey.rawValue)
        dataStore = DataStore()

        let configuration = NeuroID.Configuration(clientKey: "key_test_123456")
        neuroID = NeuroIDCore(datastore: dataStore)
        _ = neuroID.configure(configuration)

        // Clear out the DataStore Events after each test
        dataStore.removeSentEvents()
        let _ = dataStore.getAndRemoveAllEvents()
        let _ = dataStore.getAndRemoveAllQueuedEvents()
    }

    deinit {
        _ = neuroID.stop()

        // Clear out the DataStore Events after each test
        dataStore.removeSentEvents()
        let _ = dataStore.getAndRemoveAllEvents()
        let _ = dataStore.getAndRemoveAllQueuedEvents()
    }

    @Test
    func test_saveEventToLocalDataStore_stoppedSDK() {
        _ = neuroID.stop()

        neuroID.saveEventToLocalDataStore(nidEvent, screen: screenName)
        #expect(dataStore.events.count == 0)
    }

    @Test
    func test_saveEventToLocalDataStore_success() {
        let screen = "DS_TEST_SCREEN"
        neuroID._currentScreenName = screen
        neuroID.datastore = dataStore

        neuroID._isSDKStarted = true

        let nidE = nidEvent
        #expect(nidE.url == nil)

        neuroID.saveEventToLocalDataStore(nidE, screen: screenName)
        #expect(dataStore.events.count == 1)
        #expect(dataStore.events[0].url == "ios://\(screen)")
    }

    @Test
    func test_saveQueuedEventToLocalDataStore_success() {
        let screen = "DS_TEST_SCREEN"
        neuroID._currentScreenName = screen

        let nidE = nidEvent
        #expect(nidE.url == nil)

        neuroID.saveQueuedEventToLocalDataStore(nidE, screen: screenName)
        #expect(dataStore.events.count == 0)
        #expect(dataStore.queuedEvents.count == 1)
        #expect(dataStore.queuedEvents[0].url == "ios://\(screen)")
    }

    @Test
    func test_cleanAndStoreEvent_RNScreen() {
        var nidE = nidEvent
        nidE.url = "RNScreensNavigationController"

        neuroID.cleanAndStoreEvent(screen: screenName, event: nidE, storeType: "")
        #expect(dataStore.events.count == 0)
    }

    @Test
    func test_cleanAndStoreEvent_excludedView_tg() {
        neuroID.excludeViewByTestID(excludeId)

        var nidE = nidEvent
        nidE.tg = [
            "tgs": TargetValue.string(excludeId)
        ]

        neuroID.cleanAndStoreEvent(screen: screenName, event: nidE, storeType: "")
        #expect(dataStore.events.count == 0)
    }

    @Test
    func test_cleanAndStoreEvent_excludedView_tgs() {
        neuroID.excludeViewByTestID(excludeId)

        var nidE = nidEvent

        nidE.tgs = excludeId

        neuroID.cleanAndStoreEvent(screen: screenName, event: nidE, storeType: "")
        #expect(dataStore.events.count == 0)
    }

    @Test
    func test_cleanAndStoreEvent_excludedView_en() {
        neuroID.excludeViewByTestID(excludeId)

        var nidE = nidEvent

        nidE.en = excludeId

        neuroID.cleanAndStoreEvent(screen: screenName, event: nidE, storeType: "")
        #expect(dataStore.events.count == 0)
    }
}
