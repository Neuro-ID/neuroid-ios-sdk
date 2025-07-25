//
//  NeuroIDClassTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 4/5/23.
//

@testable import NeuroID
import XCTest

class NeuroIDClassTests: BaseTestClass {
    let mockService = MockDeviceSignalService()

    override func setUpWithError() throws {
        // skip all tests in this class, remove this line to re-enabled tests
//        throw XCTSkip("Skipping all tests in this class.")
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    override func setUp() {
        UserDefaults.standard.removeObject(forKey: Constants.storageAdvancedDeviceKey.rawValue)
        mockService.mockResult = .success(("mock", Double(Int.random(in: 0 ..< 3000))))
        NeuroID._isTesting = true
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
        NeuroID._isTesting = false
    }

    func test_getAdvDeviceLatency() {
        let mockService = MockDeviceSignalService()
        NeuroID.deviceSignalService = mockService
        _ = NeuroID.configure(clientKey: "key_test_0OMmplsawAp2CQfWrytWA3wL")
        let randomTimeInMilliseconds = Double(Int.random(in: 0 ..< 3000))
        mockService.mockResult = .success(("empty mock result. Can be filled with anything", randomTimeInMilliseconds))
        NeuroID.start(true) { _ in
            self.assertStoredEventCount(type: "ADVANCED_DEVICE_REQUEST", count: 1)
        }
    }

    func test_configure_success() {
        clearOutDataStore()
        // remove things configured in setup
        NeuroID.clientKey = nil
        UserDefaults.standard.setValue(nil, forKey: clientKeyKey)
        UserDefaults.standard.setValue("testTabId", forKey: tabIdKey)

        let configured = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
        assert(configured)

        let clientKeyValue = UserDefaults.standard.string(forKey: clientKeyKey)
        assert(clientKeyValue == clientKey)

        let tabIdValue = UserDefaults.standard.string(forKey: tabIdKey)
        assert(tabIdValue == nil)

        assertStoredEventCount(type: "CREATE_SESSION", count: 0)

        assert(NeuroID.environment == "\(Constants.environmentLive.rawValue)")
    }

    func test_configure_invalidKey() {
        NeuroID.setDevTestingURL()
        clearOutDataStore()
        // remove things configured in setup
        NeuroID.environment = Constants.environmentTest.rawValue
        NeuroID.clientKey = nil
        UserDefaults.standard.setValue(nil, forKey: clientKeyKey)
        UserDefaults.standard.setValue("testTabId", forKey: tabIdKey)

        let configured = NeuroID.configure(clientKey: "invalid_key", isAdvancedDevice: false)
        assert(configured == false)

        let clientKeyValue = UserDefaults.standard.string(forKey: clientKeyKey)
        assert(clientKeyValue == nil)

        let tabIdValue = UserDefaults.standard.string(forKey: tabIdKey)
        assert(tabIdValue == "testTabId-invalid-client-key")

        assertStoredEventCount(type: "CREATE_SESSION", count: 0)

        // 1 Log event should be in queue if the key fails validation
        assertQueuedEventTypeAndCount(type: "LOG", count: 1)

        assert(NeuroID.environment == "\(Constants.environmentTest.rawValue)")
    }

    func test_start_failure() {
        tearDown()
        NeuroID._isSDKStarted = false
        NeuroID.clientKey = nil

        // pre tests
        assert(!NeuroID.isSDKStarted)
        assert(NeuroID.clientKey == nil)

        // action
        NeuroID.start { started in
            assert(!started)
            // post action test
            assert(!NeuroID.isSDKStarted)
        }
    }

    func test_start_success() {
        tearDown()
        NeuroID._isSDKStarted = false
        NeuroID._isTesting = true
//        NeuroID.isAdvancedDevice = false

        // pre tests
        assert(!NeuroID.isSDKStarted)

        // action
        NeuroID.start { started in
            // post action test
            assert(started)
            assert(NeuroID.isSDKStarted)
            self.assertStoredEventCount(type: "CREATE_SESSION", count: 1)
            self.assertStoredEventCount(type: "MOBILE_METADATA_IOS", count: 1)

            NeuroID._isTesting = false
        }
    }

    func test_start_success_queuedEvent() {
        _ = NeuroID.stop()
        NeuroID._isSDKStarted = false
        NeuroID._isTesting = true

        // pre tests
        assert(!NeuroID.isSDKStarted)

        clearOutDataStore()

        // action
        NeuroID.start { started in
            // post action test
            assert(started)
            assert(NeuroID.isSDKStarted)

            self.assertStoredEventCount(type: "CREATE_SESSION", count: 1)
            self.assertStoredEventCount(type: "MOBILE_METADATA_IOS", count: 1)
            self.assertStoredEventCount(type: "APPLICATION_METADATA", count: 1)
            self.assertStoredEventCount(type: "LOG", count: 2)
            NeuroID._isTesting = false
        }
    }

    func test_stop() {
        NeuroID._isSDKStarted = true
        assert(NeuroID.isSDKStarted)

        let stopped = NeuroID.stop()
        assert(stopped)
        assert(!NeuroID.isSDKStarted)
    }

    func test_getSDKVersion() {
        let expectedValue = ParamsCreator.getSDKVersion()

        let value = NeuroID.getSDKVersion()

        assert(value == expectedValue)

        let resultAdvTrue = NeuroID.getSDKVersion()
        assert(resultAdvTrue.contains("-adv"))

        NeuroID.isRN = true
        let resultRNTrue = NeuroID.getSDKVersion()
        assert(resultRNTrue.contains("-rn"))

        NeuroID.isRN = false
        let resultRNFalse = NeuroID.getSDKVersion()
        assert(!resultRNFalse.contains("-rn"))
    }
}

// swizzle
// initTimer
// send

// groupAndPOST
// post

// logInfo
// logError
// logFault
// logDebug
// logDefault
// osLog

// saveDebugJSON
