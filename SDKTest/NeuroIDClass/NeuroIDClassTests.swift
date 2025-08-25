//
//  NeuroIDClassTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 4/5/23.
//

@testable import NeuroID
import XCTest

class NeuroIDClassTests: BaseTestClass {
    var mockIdentifierService = MockIdentifierService()
    let mockService = MockDeviceSignalService()
    var neuroID = NeuroID()

    override func setUpWithError() throws {
        // skip all tests in this class, remove this line to re-enabled tests
//        throw XCTSkip("Skipping all tests in this class.")
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    override func setUp() {
        mockIdentifierService = MockIdentifierService()
        neuroID = NeuroID(identifierService: mockIdentifierService)

        UserDefaults.standard.removeObject(forKey: Constants.storageAdvancedDeviceKey.rawValue)
        mockService.mockResult = .success(("mock", Double(Int.random(in: 0 ..< 3000))))
        NeuroID._isTesting = true
        NeuroID.shared.datastore = dataStore
        NeuroID.shared.identifierService = mockIdentifierService
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
        NeuroID._isTesting = false
    }

    func test_getAdvDeviceLatency() {
        let mockService = MockDeviceSignalService()
        NeuroID.shared.deviceSignalService = mockService
        _ = NeuroID.configure(clientKey: "key_test_0OMmplsawAp2CQfWrytWA3wL")
        let randomTimeInMilliseconds = Double(Int.random(in: 0 ..< 3000))
        mockService.mockResult = .success(("empty mock result. Can be filled with anything", randomTimeInMilliseconds))

        NeuroID.shared.configService = MockConfigService()

        NeuroID.start(true) { _ in
            self.assertStoredEventCount(type: "ADVANCED_DEVICE_REQUEST", count: 1)
        }
    }

    func test_class_var_sessionID_get() {
        let expectedValue = "testID"
        mockIdentifierService.sessionID = expectedValue

        assert(neuroID.sessionID == expectedValue)
    }

    func test_class_var_registeredUserID_get() {
        let expectedValue = "testID"
        mockIdentifierService.registeredUserID = expectedValue

        assert(neuroID.registeredUserID == expectedValue)
    }

    func test_configure_success() {
        clearOutDataStore()
        // remove things configured in setup
        NeuroID.shared.clientKey = nil
        UserDefaults.standard.setValue(nil, forKey: clientKeyKey)
        UserDefaults.standard.setValue("testTabId", forKey: tabIdKey)

        let configured = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
        assert(configured)

        let clientKeyValue = UserDefaults.standard.string(forKey: clientKeyKey)
        assert(clientKeyValue == clientKey)

        let tabIdValue = UserDefaults.standard.string(forKey: tabIdKey)
        assert(tabIdValue == nil)

        assertStoredEventCount(type: "CREATE_SESSION", count: 0)

        assert(NeuroID.shared.environment == "\(Constants.environmentLive.rawValue)")
    }

    func test_configure_invalidKey() {
        clearOutDataStore()
        // remove things configured in setup
        NeuroID.shared.environment = Constants.environmentTest.rawValue
        NeuroID.shared.clientKey = nil
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

        assert(NeuroID.shared.environment == "\(Constants.environmentTest.rawValue)")
    }

    func test_start_failure() {
        tearDown()
        NeuroID.shared._isSDKStarted = false
        NeuroID.shared.configService = MockConfigService()
        NeuroID.shared.clientKey = nil

        // pre tests
        assert(!NeuroID.shared.isSDKStarted)
        assert(NeuroID.shared.clientKey == nil)

        // action
        NeuroID.start { started in
            assert(!started)
            // post action test
            assert(!NeuroID.shared.isSDKStarted)
        }
    }

    func test_start_success() {
        tearDown()
        NeuroID.shared._isSDKStarted = false
        NeuroID.shared.configService = MockConfigService()
        NeuroID._isTesting = true
//        NeuroID.isAdvancedDevice = false

        // pre tests
        assert(!NeuroID.shared.isSDKStarted)

        // action
        NeuroID.start { started in
            // post action test
            assert(started)
            assert(NeuroID.shared.isSDKStarted)
            self.assertStoredEventCount(type: "CREATE_SESSION", count: 1)
            self.assertStoredEventCount(type: "MOBILE_METADATA_IOS", count: 1)

            NeuroID._isTesting = false
        }
    }

    func test_start_success_queuedEvent() {
        _ = NeuroID.stop()
        NeuroID.shared._isSDKStarted = false
        NeuroID.shared.configService = MockConfigService()
        NeuroID._isTesting = true

        // pre tests
        assert(!NeuroID.shared.isSDKStarted)

        clearOutDataStore()

        // action
        NeuroID.start { started in
            // post action test
            assert(started)
            assert(NeuroID.shared.isSDKStarted)

            self.assertStoredEventCount(type: "CREATE_SESSION", count: 1)
            self.assertStoredEventCount(type: "MOBILE_METADATA_IOS", count: 1)
            self.assertStoredEventCount(type: "APPLICATION_METADATA", count: 1)
            self.assertStoredEventCount(type: "LOG", count: 2)
            NeuroID._isTesting = false
        }
    }

    func test_stop() {
        NeuroID.shared._isSDKStarted = true
        assert(NeuroID.shared.isSDKStarted)

        let stopped = NeuroID.stop()
        assert(stopped)
        assert(!NeuroID.shared.isSDKStarted)
    }

    func test_getSDKVersion() {
        let expectedValue = ParamsCreator.getSDKVersion()

        let value = NeuroID.getSDKVersion()

        assert(value == expectedValue)

        let resultAdvTrue = NeuroID.getSDKVersion()
        assert(resultAdvTrue.contains("-adv"))

        NeuroID.shared.isRN = true
        let resultRNTrue = NeuroID.getSDKVersion()
        assert(resultRNTrue.contains("-rn"))

        NeuroID.shared.isRN = false
        let resultRNFalse = NeuroID.getSDKVersion()
        assert(!resultRNFalse.contains("-rn"))
    }
}

// swizzle

// logInfo
// logError
// logFault
// logDebug
// logDefault
// osLog
