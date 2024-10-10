//
//  MultiAppFlowTests.swift
//  SDKTest
//
//  Created by Clayton Selby on 5/10/24.
//

@testable import NeuroID
import XCTest

final class MultiAppFlowTests: XCTestCase {
    let clientKey = "key_test_0OMmplsawAp2CQfWrytWA3wL"

    // Keys for storage:
    let localStorageNIDStopAll = Constants.storageLocalNIDStopAllKey.rawValue
    let clientKeyKey = Constants.storageClientKey.rawValue
    let tabIdKey = Constants.storageTabIDKey.rawValue

    let mockService = MockDeviceSignalService()
    let mockedConfig = MockConfigService()

    func clearOutDataStore() {
        let _ = DataStore.getAndRemoveAllEvents()
    }

    override func setUpWithError() throws {}

    override func setUp() {
        NeuroID.clientKey = nil
        NeuroID.configService = mockedConfig
        UserDefaults.standard.removeObject(forKey: Constants.storageAdvancedDeviceKey.rawValue)
        mockService.mockResult = .success(("mock", Double(Int.random(in: 0 ..< 3000))))
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    func test_start_adv_true() {
        _ = NeuroID.configure(clientKey: clientKey)
        NeuroID.deviceSignalService = mockService
        NeuroID.start(true) { _ in
            let validEvent = DataStore.getAllEvents().filter { $0.type == "ADVANCED_DEVICE_REQUEST" }

            assert(!NeuroID.isAdvancedDevice)
            assert(validEvent.count == 1)
        }
    }

    func test_start_session_configure_adv_true() {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: true)
        NeuroID.deviceSignalService = mockService

        NeuroID.startSession("fake_user_session") { _ in
            let validEvent = DataStore.getAllEvents().filter { $0.type == "ADVANCED_DEVICE_REQUEST" }

            assert(NeuroID.isAdvancedDevice)
            assert(validEvent.count == 1)
        }
    }

    func test_start_start_app_flow_configure_adv_true() {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: true)
        NeuroID.deviceSignalService = mockService

        NeuroID.startAppFlow(siteID: "form_dream102", userID: "jakeId") { _ in
            let validEvent = DataStore.getAllEvents().filter { $0.type == "ADVANCED_DEVICE_REQUEST" }

            assert(NeuroID.isAdvancedDevice)
            assert(validEvent.count == 1)
        }
    }

    func test_start_configure_adv_true() {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: true)
        NeuroID.deviceSignalService = mockService
        NeuroID.start { _ in
            let validEvent = DataStore.getAllEvents().filter { $0.type == "ADVANCED_DEVICE_REQUEST" }
            assert(NeuroID.isAdvancedDevice)
            assert(validEvent.count == 1)
        }
    }

    func test_start_session_adv_true() {
        _ = NeuroID.configure(clientKey: clientKey)
        NeuroID.deviceSignalService = mockService
        NeuroID.startSession("fake_user_session", true) { _ in

            let validEvent = DataStore.getAllEvents().filter { $0.type == "ADVANCED_DEVICE_REQUEST" }
            XCTAssert(!NeuroID.isAdvancedDevice)
            XCTAssertTrue(validEvent.count == 1)
        }
    }

    func test_captureAdvancedDevice_throttle() {
        _ = NeuroID.configure(clientKey: clientKey)
        NeuroID.deviceSignalService = mockService
        NeuroID._isSDKStarted = true

        let service = NIDSamplingService()
        service._isSessionFlowSampled = false
        NeuroID.samplingService = service // setting to false indicating we are throttling

        NeuroID.captureAdvancedDevice([true]) // passing true to indicate we should capture

        let validEvent = DataStore.getAllEvents().filter { $0.type == "ADVANCED_DEVICE_REQUEST" }
        assert(validEvent.count == 0)

        service._isSessionFlowSampled = true
        NeuroID._isSDKStarted = false
    }

    func test_captureAdvancedDevice_no_throttle() {
        _ = NeuroID.configure(clientKey: clientKey)
        NeuroID.deviceSignalService = mockService
        NeuroID._isSDKStarted = true

        let service = NIDSamplingService()
        service._isSessionFlowSampled = true // setting to true indicating we are NOT throttling
        NeuroID.samplingService = service

        NeuroID.captureAdvancedDevice([true]) // passing true to indicate we should capture

        let validEvent = DataStore.getAllEvents().filter { $0.type == "ADVANCED_DEVICE_REQUEST" }
        assert(validEvent.count == 1)

        NeuroID._isSDKStarted = false
    }
}
