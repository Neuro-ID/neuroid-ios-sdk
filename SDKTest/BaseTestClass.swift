//
//  BaseTestClass.swift
//  SDKTest
//
//  Created by Kevin Sites on 1/21/25.
//


@testable import NeuroID
import XCTest

class BaseTestClass: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"
    
    // Keys for storage:
    let localStorageNIDStopAll = Constants.storageLocalNIDStopAllKey.rawValue
    let clientKeyKey = Constants.storageClientKey.rawValue
    let clientIdKey = Constants.storageClientIDKey.rawValue
    let tabIdKey = Constants.storageTabIDKey.rawValue
    
    func clearOutDataStore() {
        NeuroID.datastore.removeSentEvents()
        let _ = NeuroID.datastore.getAndRemoveAllEvents()
        let _ = NeuroID.datastore.getAndRemoveAllQueuedEvents()
    }
    
    override func setUpWithError() throws {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
    }
    
    override func setUp() {
        UserDefaults.standard.removeObject(forKey: Constants.storageAdvancedDeviceKey.rawValue)
    }
    
    override func tearDown() {
        _ = NeuroID.stop()
        
        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }
    
    func assertDataStoreCount(count: Int) {
        let allEvents = NeuroID.datastore.getAllEvents()
        assert(allEvents.count == count)
    }
    
    func assertStoredEventCount(type: String, count: Int) {
        let allEvents = NeuroID.datastore.getAllEvents()
        let validEvent = allEvents.filter { $0.type == type }
        assert(validEvent.count == count)
    }

    func assertStoredEventTypeAndCount(type: String, count: Int, skipType: Bool? = false) {
        let allEvents = NeuroID.datastore.getAllEvents()
        let validEvent = allEvents.filter { $0.type == type }
        assert(validEvent.count == count)
        if !skipType! && validEvent.count > 0 {
            assert(validEvent[0].type == type)
        }
    }

    func assertQueuedEventTypeAndCount(type: String, count: Int, skipType: Bool? = false) {
        let allEvents = NeuroID.datastore.queuedEvents
        let validEvent = allEvents.filter { $0.type == type }
        assert(validEvent.count == count)
        if !skipType! {
            assert(validEvent[0].type == type)
        }
    }
    
    func assertDatastoreEventOrigin(type: String, origin: String, originCode: String, queued: Bool) {
        let allEvents = queued ? NeuroID.datastore.queuedEvents : NeuroID.datastore.getAllEvents()
        
        let validEvents = allEvents.filter { $0.type == type }

        let originEvent = validEvents.filter { $0.key == "sessionIdSource" }
        assert(originEvent.count == 1)
        assert(originEvent[0].v == origin)

        let originCodeEvent = validEvents.filter { $0.key == "sessionIdCode" }
        assert(originCodeEvent.count == 1)
        assert(originCodeEvent[0].v == originCode)
    }
}
