//
//  NIDPerformanceTests.swift
//  SDKTest
//
//  Created by Clayton Selby on 2/12/24.
//

@testable import NeuroID
import XCTest

final class NIDPerformanceTests: XCTestCase {

    let clientKey = "key_live_vtotrandom_form_mobilesandbox";
    
    func clearOutDataStore() {
        let _ = DataStore.getAndRemoveAllEvents()
    }

    override func setUpWithError() throws {
        NeuroID.captureGyroCadence = false
        _ = NeuroID.configure(clientKey: clientKey)
    }

    override func setUp() {
        NeuroID.networkService = NIDNetworkServiceTestImpl.init()
        _ = NeuroID.start()
    }

    override func tearDown() {
        _ = NeuroID.stop()
        
        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    func testBufferFull() throws {
        
        for i in 1...3000 {
            let expectedValue = "myTestUserID"
            let result = NeuroID.setGenericUserID(
                userId: expectedValue,
                type: .registeredUserID
            ) { res in
                res
            }
        }
        print("NID Size: \(DataStore.events.count)")
        assert(DataStore.events.count <= 2001)
        assert(DataStore.events.last!.type == NIDEventName.bufferFull.rawValue)
    }
    
    func testQueuedEvents() throws {
        _ = NeuroID.stop()
        for i in 1...3000 {
            let expectedValue = "myTestUserID"
            let result = NeuroID.setGenericUserID(
                userId: expectedValue,
                type: .registeredUserID
            ) { res in
                res
            }
        }
        print("NID Size: \(DataStore.queuedEvents.count)")
        assert(DataStore.queuedEvents.count <= 2001)
        assert(DataStore.queuedEvents.last!.type == NIDEventName.bufferFull.rawValue)
    }
}
