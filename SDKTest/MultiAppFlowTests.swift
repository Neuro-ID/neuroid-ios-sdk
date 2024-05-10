//
//  MultiAppFlowTests.swift
//  SDKTest
//
//  Created by Clayton Selby on 5/10/24.
//


@testable import NeuroID
@testable import NeuroIDAdvancedDevice
import XCTest

final class MultiAppFlowTests: XCTestCase {

    let clientKey = "key_test_0OMmplsawAp2CQfWrytWA3wL"

    // Keys for storage:
    let localStorageNIDStopAll = Constants.storageLocalNIDStopAllKey.rawValue
    let clientKeyKey = Constants.storageClientKey.rawValue
    let tabIdKey = Constants.storageTabIDKey.rawValue

    let mockService = MockDeviceSignalService()

    func clearOutDataStore() {
        let _ = DataStore.getAndRemoveAllEvents()
    }

    override func setUpWithError() throws {
    }

    override func setUp() {
        NeuroID.clientKey = nil
        UserDefaults.standard.removeObject(forKey: Constants.storageAdvancedDeviceKey.rawValue)
        mockService.mockResult = .success(("mock", Double(Int.random(in: 0..<3000))))
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }


    func test_start_session_configure_adv_true() {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: true)
        NeuroID.deviceSignalService = mockService
        _ = NeuroID.startSession("fake_user_session")
        
        let validEvent = DataStore.getAllEvents().filter { $0.type == "ADVANCED_DEVICE_REQUEST" }
        
        XCTAssert(NeuroID.isAdvancedDevice)
        XCTAssertTrue(validEvent.count == 1)
    }
    
    func test_start_start_app_flow_configure_adv_true() {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: true)
        NeuroID.deviceSignalService = mockService
        _ = NeuroID.startAppFlow(siteID: "form_dream102", userID: "jakeId")

        let validEvent = DataStore.getAllEvents().filter { $0.type == "ADVANCED_DEVICE_REQUEST" }
        
        XCTAssert(NeuroID.isAdvancedDevice)
        XCTAssertTrue(validEvent.count == 1)
    }
    
    func test_start_adv_true() {
        _ = NeuroID.configure(clientKey: clientKey)
        NeuroID.deviceSignalService = mockService
        _ = NeuroID.start(true)
    
        let validEvent = DataStore.getAllEvents().filter { $0.type == "ADVANCED_DEVICE_REQUEST" }
        
        XCTAssert(!NeuroID.isAdvancedDevice)
        XCTAssertTrue(validEvent.count == 1)
    }
    
    func test_start_configure_adv_true(){
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: true)
        NeuroID.deviceSignalService = mockService
        _ = NeuroID.start()
           
        let validEvent = DataStore.getAllEvents().filter { $0.type == "ADVANCED_DEVICE_REQUEST" }
        XCTAssert(NeuroID.isAdvancedDevice)
        XCTAssertTrue(validEvent.count == 1)
    }
    
    func test_start_session_adv_true() {
        _ = NeuroID.configure(clientKey: clientKey)
        NeuroID.deviceSignalService = mockService
        _ = NeuroID.startSession("fake_user_session", true)
        
        let validEvent = DataStore.getAllEvents().filter { $0.type == "ADVANCED_DEVICE_REQUEST" }
        XCTAssert(!NeuroID.isAdvancedDevice)
        XCTAssertTrue(validEvent.count == 1)
    }
}
