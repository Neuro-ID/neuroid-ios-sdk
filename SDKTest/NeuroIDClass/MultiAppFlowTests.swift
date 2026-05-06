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

    let mockService = MockDeviceSignalService()
    let mockedConfig = MockConfigService()
    var mockedNetworkService = MockNetworkService()

    func clearOutDataStore() {
        let _ = NeuroIDCore.shared.datastore.getAndRemoveAllEvents()
    }

    override func setUpWithError() throws {
        // skip all tests in this class, remove this line to re-enabled tests
    }

    override func setUp() {
        NeuroIDCore.shared.clientKey = nil
        NeuroIDCore.shared.configService = getMockConfigService(shouldFail: false, randomGenerator: MockedNIDRandomGenerator(0))

        mockedNetworkService = MockNetworkService()
        mockedNetworkService.mockResponse = try! JSONEncoder().encode(RemoteConfiguration.mock())
        mockedNetworkService.mockResponseResult = RemoteConfiguration.mock()

        NeuroIDCore.shared.networkService = mockedNetworkService

        UserDefaults.standard.removeObject(forKey: Constants.storageAdvancedDeviceKey.rawValue)
        mockService.mockResult = .success(("mock", Double(Int.random(in: 0 ..< 3000)), nil))

        NeuroIDCore.shared.deviceSignalService = mockService
        NeuroIDCore._isTesting = true
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
        NeuroIDCore._isTesting = false
    }

    func test_start_adv_true() {
        NeuroIDCore.shared.clientKey = ""
        let configuration = NeuroID.Configuration(clientKey: clientKey)
        _ = NeuroID.configure(configuration)
        NeuroIDCore.shared.configService = mockedConfig
        clearOutDataStore()

        NeuroID.start(true) { _ in
            let validEvent = NeuroIDCore.shared.datastore.getAllEvents().filter {
                $0.type == "ADVANCED_DEVICE_REQUEST"
            }

            assert(!NeuroIDCore.shared.isAdvancedDevice)
            assert(validEvent.count == 1)
        }
    }

    func test_start_configure_adv_true() {
        NeuroIDCore.shared.clientKey = ""

        let configuration = NeuroID.Configuration(clientKey: clientKey, isAdvancedDevice: true)
        _ = NeuroID.configure(configuration)
        NeuroIDCore.shared.configService = mockedConfig
        clearOutDataStore()

        NeuroID.start { _ in
            let validEvent = NeuroIDCore.shared.datastore.getAllEvents().filter {
                $0.type == "ADVANCED_DEVICE_REQUEST"
            }
            assert(NeuroIDCore.shared.isAdvancedDevice)
            assert(validEvent.count == 1)
        }
    }

    func test_start_session_adv_true() {
        NeuroIDCore.shared.clientKey = ""
        let configuration = NeuroID.Configuration(clientKey: clientKey)
        _ = NeuroID.configure(configuration)
        NeuroIDCore.shared.configService = mockedConfig
        clearOutDataStore()

        NeuroID.startSession("fake_user_session", true) { _ in

            let validEvent = NeuroIDCore.shared.datastore.getAllEvents().filter {
                $0.type == "ADVANCED_DEVICE_REQUEST"
            }
            XCTAssert(!NeuroIDCore.shared.isAdvancedDevice)
            XCTAssertTrue(validEvent.count == 1)
        }
    }

    func test_start_session_configure_adv_true() {
        NeuroIDCore.shared.clientKey = ""
        let configuration = NeuroID.Configuration(clientKey: clientKey, isAdvancedDevice: true)
        _ = NeuroID.configure(configuration)
        NeuroIDCore.shared.configService = mockedConfig
        clearOutDataStore()

        NeuroID.startSession("fake_user_session") { _ in
            let validEvent = NeuroIDCore.shared.datastore.getAllEvents().filter {
                $0.type == "ADVANCED_DEVICE_REQUEST"
            }

            assert(NeuroIDCore.shared.isAdvancedDevice)
            assert(validEvent.count == 1)
        }
    }

    func test_start_start_app_flow_configure_adv_true() {
        NeuroIDCore.shared.clientKey = ""
        let configuration = NeuroID.Configuration(clientKey: clientKey, isAdvancedDevice: true)
        _ = NeuroID.configure(configuration)
        NeuroIDCore.shared.configService = mockedConfig
        clearOutDataStore()

        NeuroID.startAppFlow(siteID: "form_dream102", sessionID: "jakeId") { _ in
            let validEvent = NeuroIDCore.shared.datastore.getAllEvents().filter {
                $0.type == "ADVANCED_DEVICE_REQUEST"
            }

            assert(NeuroIDCore.shared.isAdvancedDevice)
            assert(validEvent.count == 1)
        }
    }

    func test_captureAdvancedDevice_throttle() async {
        NeuroIDCore.shared.clientKey = ""
        NeuroIDCore.shared.deviceSignalService = mockService
        let configuration = NeuroID.Configuration(clientKey: clientKey)
        _ = NeuroID.configure(configuration)
        NeuroIDCore.shared._isSDKStarted = true

        let service = getMockConfigService(
            shouldFail: false,
            randomGenerator: MockedNIDRandomGenerator(0)
        )
        service._isSessionFlowSampled = false
        await service.retrieveConfig()
        NeuroIDCore.shared.configService = service // setting to false indicating we are throttling

        NeuroIDCore.shared.captureAdvancedDevice(true) // passing true to indicate we should capture

        let validEvent = NeuroIDCore.shared.datastore.getAllEvents().filter {
            $0.type == "ADVANCED_DEVICE_REQUEST"
        }
        assert(validEvent.count == 0)

        service._isSessionFlowSampled = true
        NeuroIDCore.shared._isSDKStarted = false
    }

    func test_captureAdvancedDevice_no_throttle() async {
        NeuroIDCore.shared.clientKey = ""
        let configuration = NeuroID.Configuration(clientKey: clientKey)
        _ = NeuroID.configure(configuration)
        NeuroIDCore.shared.deviceSignalService = mockService
        NeuroIDCore.shared._isSDKStarted = true

        let service = getMockConfigService(
            shouldFail: false,
            randomGenerator: MockedNIDRandomGenerator(0)
        )

        service._isSessionFlowSampled = true // setting to true indicating we are NOT throttling
        NeuroIDCore.shared.configService = service

        NeuroIDCore.shared.captureAdvancedDevice(true) // passing true to indicate we should capture
        await service.retrieveConfig()

        let validEvent = NeuroIDCore.shared.datastore.getAllEvents().filter {
            $0.type == "ADVANCED_DEVICE_REQUEST"
        }
        assert(validEvent.count == 1)

        NeuroIDCore.shared._isSDKStarted = false
    }
}
