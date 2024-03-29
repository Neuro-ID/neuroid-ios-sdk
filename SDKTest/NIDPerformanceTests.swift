//
//  NIDPerformanceTests.swift
//  SDKTest
//
//  Created by Clayton Selby on 2/12/24.
//

@testable import NeuroID
import XCTest

final class NIDPerformanceTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"
    
    func clearOutDataStore() {
        let _ = DataStore.getAndRemoveAllEvents()
    }

    override func setUpWithError() throws {
        NeuroID.captureGyroCadence = false
        _ = NeuroID.configure(clientKey: clientKey)
    }

    override func setUp() {
        NeuroID.networkService = NIDNetworkServiceTestImpl()
        
        _ = NeuroID.start()
    }

    override func tearDown() {
        _ = NeuroID.stop()
        NeuroID.collectionURL = Constants.productionURL.rawValue
        NeuroID.lowMemory = false
        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    func testBufferFull() throws {
        for _ in 1...3000 {
            let expectedValue = "myTestUserID"
            _ = NeuroID.setGenericUserID(
                userId: expectedValue,
                type: .registeredUserID
            ) { res in
                res
            }
        }
        print("NID Event Size: \(DataStore.events.count)")
        assert(DataStore.events.count <= 2001)
        assert(DataStore.events.last!.type == NIDEventName.bufferFull.rawValue)
    }
    
    func testQueuedEvents() throws {
        _ = NeuroID.stop()
        for _ in 1...3000 {
            let expectedValue = "myTestUserID"
            _ = NeuroID.setGenericUserID(
                userId: expectedValue,
                type: .registeredUserID
            ) { res in
                res
            }
        }
        print("NID Queue Size: \(DataStore.queuedEvents.count)")
        assert(DataStore.queuedEvents.count <= 2001)
        assert(DataStore.queuedEvents.last?.type == NIDEventName.bufferFull.rawValue)
    }
    
    func testLowMemory() throws {
        // Setup a view and invoke observeAppEvents to get listeners attached for the test
        let uiView = UITextView()
        
        let screenNameValue = "testScreen"
        
        let tracker = NeuroIDTracker(screen: "Temp", controller: uiView.inputViewController)

        let guidValue = "\(Constants.attrGuidKey.rawValue)"
        
        tracker.observeAppEvents()
        
        NeuroIDTracker.registerSingleView(v: uiView, screenName: screenNameValue, guid: guidValue)
            
        // Manually trigger low memory event
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        for _ in 1...100 {
            let expectedValue = "myTestUserID"
            _ = NeuroID.setGenericUserID(
                userId: expectedValue,
                type: .registeredUserID
            ) { res in
                res
            }
        }
        print("NID Event Size low Memory: \(DataStore.events.count)")
        assert(DataStore.events.count == 0)
    }
}
