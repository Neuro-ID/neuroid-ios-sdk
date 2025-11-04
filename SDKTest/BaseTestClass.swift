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
    
    var dataStore = DataStore(logger: NIDLog())
    
    func clearOutDataStore() {
        NeuroID.shared.datastore.removeSentEvents()
        let _ = NeuroID.shared.datastore.getAndRemoveAllEvents()
        let _ = NeuroID.shared.datastore.getAndRemoveAllQueuedEvents()
    }
    
    override func setUpWithError() throws {
        let configuration = NeuroID.Configuration(clientKey: clientKey, isAdvancedDevice: false)
        _ = NeuroID.configure(configuration)
        NeuroID.shared.sendCollectionEventsJob.cancel()
        NeuroID.shared.collectGyroAccelEventJob.cancel()
    }
    
    override func setUp() {
        NeuroID.shared.datastore = dataStore
        
        let mockedNetworkService = MockNetworkService()
        mockedNetworkService.mockResponse = try! JSONEncoder().encode(getMockResponseData())
        mockedNetworkService.mockResponseResult = getMockResponseData()

        NeuroID.shared.networkService = mockedNetworkService
        
        UserDefaults.standard.removeObject(forKey: Constants.storageAdvancedDeviceKey.rawValue)
    }
    
    override func tearDown() {
        _ = NeuroID.stop()
        
        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }
    
    func assertDataStoreCount(count: Int) {
        let allEvents = NeuroID.shared.datastore.getAllEvents()
        XCTAssertEqual(allEvents.count, count, "Expected \(count) events in datastore but found \(allEvents.count)")
    }

    func assertStoredEventCount(type: String, count: Int) {
        let allEvents = NeuroID.shared.datastore.getAllEvents()
        let validEvent = allEvents.filter { $0.type == type }
        XCTAssertEqual(validEvent.count, count, "Expected \(count) events of type '\(type)' but found \(validEvent.count)")
    }

    func assertStoredEventTypeAndCount(type: String, count: Int, skipType: Bool? = false) {
        let allEvents = NeuroID.shared.datastore.getAllEvents()
        let validEvent = allEvents.filter { $0.type == type }
        XCTAssertEqual(validEvent.count, count, "Expected \(count) events of type '\(type)' but found \(validEvent.count)")
        
        if !skipType! && validEvent.count > 0 {
            XCTAssertEqual(validEvent[0].type, type, "Expected event type '\(type)' but found '\(validEvent[0].type)'")
        }
    }
    
    func assertStoredEventTypeAndCount(
        dataStoreEvents: [NIDEvent],
        type: String,
        count: Int,
        skipType: Bool? = false
    ) -> [NIDEvent] {
        let allEvents = dataStoreEvents
        let validEvents = allEvents.filter { $0.type == type }
        XCTAssertEqual(validEvents.count, count, "Expected \(count) events of type '\(type)' but found \(validEvents.count)")
        
        if !skipType! && validEvents.count > 0 {
            XCTAssertEqual(validEvents[0].type, type, "Expected event type '\(type)' but found '\(validEvents[0].type)'")
        }
        return validEvents
    }

    func assertQueuedEventTypeAndCount(type: String, count: Int, skipType: Bool? = false) {
        let allEvents = dataStore.queuedEvents
        let validEvent = allEvents.filter { $0.type == type }
        XCTAssertEqual(validEvent.count, count, "Expected \(count) queued events of type '\(type)' but found \(validEvent.count)")
        
        if !skipType! && validEvent.count > 0 {
            XCTAssertEqual(validEvent[0].type, type, "Expected queued event type '\(type)' but found '\(validEvent[0].type)'")
        }
    }

    func assertDatastoreEventOrigin(type: String, origin: String, originCode: String, queued: Bool) {
        let allEvents = queued ? dataStore.queuedEvents : dataStore.getAllEvents()
        let validEvents = allEvents.filter { $0.type == type }
        
        let originEvent = validEvents.filter { $0.key == "sessionIdSource" }
        XCTAssertEqual(originEvent.count, 1, "Expected 1 sessionIdSource event but found \(originEvent.count)")
        
        if originEvent.count > 0 {
            XCTAssertEqual(originEvent[0].v, origin, "Expected origin '\(origin)' but found '\(originEvent[0].v ?? "nil")'")
        }
        
        let originCodeEvent = validEvents.filter { $0.key == "sessionIdCode" }
        XCTAssertEqual(originCodeEvent.count, 1, "Expected 1 sessionIdCode event but found \(originCodeEvent.count)")
        
        if originCodeEvent.count > 0 {
            XCTAssertEqual(originCodeEvent[0].v, originCode, "Expected origin code '\(originCode)' but found '\(originCodeEvent[0].v ?? "nil")'")
        }
    }
}
