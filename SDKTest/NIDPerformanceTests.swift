//
//  NIDPerformanceTests.swift
//  SDKTest
//
//  Created by Clayton Selby on 2/12/24.
//

@testable import NeuroID
import XCTest

final class NIDPerformanceTests: XCTestCase {
    
    var sampleService: NIDSamplingService = .init()
    let mockedConfigService = MockConfigService()
    
    let childSiteID = "form_weeee"

    override func setUpWithError() throws {
        mockedConfigService.configCache = ConfigResponseData()
        sampleService = NIDSamplingService(configService: mockedConfigService)
        NeuroID.configService = mockedConfigService
        
    }
    
    func test_remote_backoff_overrides_default() {
        mockedConfigService.configCache.lowMemoryBackOff = 0
        assert(mockedConfigService.configCache.lowMemoryBackOff != NIDConfigService.DEFAULT_LOW_MEMORY_BACK_OFF)
    }
    
    func testLowMemoryFlagChangesAfterDefaultConfigSeconds() {
        NeuroID.lowMemory = false
        let expectation = self.expectation(description: "LowMemory flag should be true and then false after 5 seconds")
        
        let neuroIDTracker = NeuroIDTracker(screen: "test", controller: UIViewController())
        neuroIDTracker.appLowMemoryWarning()
        
        // Check if lowMemory is set to true after a low memory event
        XCTAssertTrue(NeuroID.lowMemory)
        
        // Wait for 5 seconds and check if the flag is set to false
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.1) {
            XCTAssertFalse(NeuroID.lowMemory)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 6.0, handler: nil)
    }
    
    func testLowMemoryFlagChangesAfterDefaultOverrideToZeroSeconds() {
        NeuroID.lowMemory = false
        
        mockedConfigService.configCache.lowMemoryBackOff = 0
        
        let expectation = self.expectation(description: "LowMemory flag should be true and then false after 0 seconds")
        
        let neuroIDTracker = NeuroIDTracker(screen: "test", controller: UIViewController())
        
        neuroIDTracker.appLowMemoryWarning()
        
        // Check if lowMemory is set to true after a low memory event
        XCTAssertTrue(NeuroID.lowMemory)
        
        // Ensure lowMemory flag was immediately toggled back so we dont drop events
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            XCTAssertFalse(NeuroID.lowMemory)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 6.0, handler: nil)
    }
//    let clientKey = "key_live_vtotrandom_form_mobilesandbox"
//    
//    func clearOutDataStore() {
//        let _ = DataStore.getAndRemoveAllEvents()
//    }
//
//    override func setUpWithError() throws {
//        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
//    }
//
//    override func setUp() {
//        NeuroID.networkService = NIDNetworkServiceTestImpl()
//        NeuroID._isSDKStarted = true
//    }
//
//    override func tearDown() {
//        _ = NeuroID.stop()
//        NeuroID.collectionURL = Constants.productionURL.rawValue
//        NeuroID.lowMemory = false
//        // Clear out the DataStore Events after each test
//        clearOutDataStore()
//    }
//
//    /**
//     Perforamnce tests are in one test to ensure test is not async with others and to prevent hanging*/
//    func all_performance_tests() throws {
//        // Buffer flow
//        for _ in 1...3000 {
//            let expectedValue = "myTestUserID"
//            _ = NeuroID.setGenericUserID(
//                userId: expectedValue,
//                type: .registeredUserID
//            ) { res in
//                res
//            }
//        }
//        print("NID Event Size: \(DataStore.events.count)")
//        assert(DataStore.events.count <= 2010)
//        assert(DataStore.events.last!.type == NIDEventName.bufferFull.rawValue)
//        
//        // Test Queued Events
//        _ = NeuroID.stop()
//        for _ in 1...2100 {
//            let expectedValue = "myTestUserID"
//            _ = NeuroID.setGenericUserID(
//                userId: expectedValue,
//                type: .registeredUserID
//            ) { res in
//                res
//            }
//        }
//        print("NID Queue Size: \(DataStore.queuedEvents.count)")
//        assert(DataStore.queuedEvents.count <= 2010)
//        assert(DataStore.queuedEvents.last?.type == NIDEventName.bufferFull.rawValue)
//        
//        // Test low memory
//        // Setup a view and invoke observeAppEvents to get listeners attached for the test
//        let uiView = UITextView()
//        
//        let screenNameValue = "testScreen"
//        
//        let tracker = NeuroIDTracker(screen: "Temp", controller: uiView.inputViewController)
//
//        let guidValue = "\(Constants.attrGuidKey.rawValue)"
//        
//        tracker.observeAppEvents()
//        
//        NeuroIDTracker.registerSingleView(v: uiView, screenName: screenNameValue, guid: guidValue)
//            
//        // Manually trigger low memory event
//        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
//        
//        for _ in 1...100 {
//            let expectedValue = "myTestUserID"
//            _ = NeuroID.setGenericUserID(
//                userId: expectedValue,
//                type: .registeredUserID
//            ) { res in
//                res
//            }
//        }
//        print("NID Event Size low Memory: \(DataStore.events.count)")
//        assert(DataStore.events.count == 0)
//    }
}
