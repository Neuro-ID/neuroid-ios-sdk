//
//  MultiAppFlowTests.swift
//  SDKTest
//
//  Created by Clayton Selby on 5/10/24.
//

import XCTest

@testable import NeuroID

class MultiAppFlowTests: XCTestCase {
    let clientKey = "key_test_0OMmplsawAp2CQfWrytWA3wL"

    // Keys for storage:
    let localStorageNIDStopAll = Constants.storageLocalNIDStopAllKey.rawValue
    let clientKeyKey = Constants.storageClientKey.rawValue
    let tabIdKey = Constants.storageTabIDKey.rawValue

    let mockService = MockDeviceSignalService()
    let mockedConfig = MockConfigService()
    var mockedNetworkService = MockNetworkService()

    func clearOutDataStore() {
        let _ = NeuroID.shared.datastore.getAndRemoveAllEvents()
    }

    override func setUpWithError() throws {
        // skip all tests in this class, remove this line to re-enabled tests
    }

    override func setUp() {
        NeuroID.shared.clientKey = nil
        NeuroID.shared.configService = getMockConfigService(shouldFail: false, randomGenerator: MockedNIDRandomGenerator(0))

        mockedNetworkService = MockNetworkService()
        mockedNetworkService.mockResponse = try! JSONEncoder().encode(getMockResponseData())
        mockedNetworkService.mockResponseResult = getMockResponseData()

        NeuroID.shared.networkService = mockedNetworkService

        UserDefaults.standard.removeObject(forKey: Constants.storageAdvancedDeviceKey.rawValue)
        mockService.mockResult = .success(("mock", Double(Int.random(in: 0 ..< 3000))))

        NeuroID.shared.deviceSignalService = mockService
        NeuroID._isTesting = true
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
        NeuroID._isTesting = false
    }

    func test_start_adv_true() {
        NeuroID.shared.clientKey = ""
        _ = NeuroID.configure(clientKey: clientKey)
        NeuroID.shared.configService = mockedConfig
        clearOutDataStore()

        NeuroID.start(true) { _ in
            let validEvent = NeuroID.shared.datastore.getAllEvents().filter {
                $0.type == "ADVANCED_DEVICE_REQUEST"
            }

            assert(!NeuroID.shared.isAdvancedDevice)
            assert(validEvent.count == 1)
        }
    }

    func test_start_configure_adv_true() {
        NeuroID.shared.clientKey = ""

        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: true)
        NeuroID.shared.configService = mockedConfig
        clearOutDataStore()

        NeuroID.start { _ in
            let validEvent = NeuroID.shared.datastore.getAllEvents().filter {
                $0.type == "ADVANCED_DEVICE_REQUEST"
            }
            assert(NeuroID.shared.isAdvancedDevice)
            assert(validEvent.count == 1)
        }
    }

    func test_start_session_adv_true() {
        NeuroID.shared.clientKey = ""
        _ = NeuroID.configure(clientKey: clientKey)
        NeuroID.shared.configService = mockedConfig
        clearOutDataStore()

        NeuroID.startSession("fake_user_session", true) { _ in

            let validEvent = NeuroID.shared.datastore.getAllEvents().filter {
                $0.type == "ADVANCED_DEVICE_REQUEST"
            }
            XCTAssert(!NeuroID.shared.isAdvancedDevice)
            XCTAssertTrue(validEvent.count == 1)
        }
    }

    func test_start_session_configure_adv_true() {
        NeuroID.shared.clientKey = ""
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: true)
        NeuroID.shared.configService = mockedConfig
        clearOutDataStore()

        NeuroID.startSession("fake_user_session") { _ in
            let validEvent = NeuroID.shared.datastore.getAllEvents().filter {
                $0.type == "ADVANCED_DEVICE_REQUEST"
            }

            assert(NeuroID.shared.isAdvancedDevice)
            assert(validEvent.count == 1)
        }
    }

    func test_start_start_app_flow_configure_adv_true() {
        NeuroID.shared.clientKey = ""
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: true)
        NeuroID.shared.configService = mockedConfig
        clearOutDataStore()

        NeuroID.startAppFlow(siteID: "form_dream102", sessionID: "jakeId") { _ in
            let validEvent = NeuroID.shared.datastore.getAllEvents().filter {
                $0.type == "ADVANCED_DEVICE_REQUEST"
            }

            assert(NeuroID.shared.isAdvancedDevice)
            assert(validEvent.count == 1)
        }
    }

    func test_captureAdvancedDevice_throttle() {
        NeuroID.shared.clientKey = ""
        NeuroID.shared.deviceSignalService = mockService
        _ = NeuroID.configure(clientKey: clientKey)
        NeuroID.shared._isSDKStarted = true

        let service = getMockConfigService(
            shouldFail: false,
            randomGenerator: MockedNIDRandomGenerator(0)
        )
        service._isSessionFlowSampled = false
        service.retrieveConfig()
        NeuroID.shared.configService = service // setting to false indicating we are throttling

        NeuroID.shared.captureAdvancedDevice(true) // passing true to indicate we should capture

        let validEvent = NeuroID.shared.datastore.getAllEvents().filter {
            $0.type == "ADVANCED_DEVICE_REQUEST"
        }
        assert(validEvent.count == 0)

        service._isSessionFlowSampled = true
        NeuroID.shared._isSDKStarted = false
    }

    func test_captureAdvancedDevice_no_throttle() {
        NeuroID.shared.clientKey = ""
        _ = NeuroID.configure(clientKey: clientKey)
        NeuroID.shared.deviceSignalService = mockService
        NeuroID.shared._isSDKStarted = true

        let service = getMockConfigService(
            shouldFail: false,
            randomGenerator: MockedNIDRandomGenerator(0)
        )

        service._isSessionFlowSampled = true // setting to true indicating we are NOT throttling
        NeuroID.shared.configService = service

        NeuroID.shared.captureAdvancedDevice(true) // passing true to indicate we should capture
        service.retrieveConfig()

        let validEvent = NeuroID.shared.datastore.getAllEvents().filter {
            $0.type == "ADVANCED_DEVICE_REQUEST"
        }
        assert(validEvent.count == 1)

        NeuroID.shared._isSDKStarted = false
    }
}
