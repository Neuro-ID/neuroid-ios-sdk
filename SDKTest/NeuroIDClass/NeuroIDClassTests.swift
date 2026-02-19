//
//  NeuroIDClassTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 4/5/23.
//

@testable import NeuroID
import XCTest

class NeuroIDClassTests: BaseTestClass {
    var mockedNetworkService = MockNetworkService()
    var mockIdentifierService = MockIdentifierService()
    let mockService = MockDeviceSignalService()
    var neuroID = NeuroIDCore()

    override func setUpWithError() throws {
        // skip all tests in this class, remove this line to re-enabled tests
//        throw XCTSkip("Skipping all tests in this class.")
        let configuration = NeuroID.Configuration(clientKey: clientKey, isAdvancedDevice: false)
        _ = NeuroID.configure(configuration)
        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    override func setUp() {
        mockIdentifierService = MockIdentifierService()
        neuroID = NeuroIDCore(identifierService: mockIdentifierService)

        UserDefaults.standard.removeObject(forKey: Constants.storageAdvancedDeviceKey.rawValue)
        mockService.mockResult = .success(("mock", Double(Int.random(in: 0 ..< 3000)), nil))
        NeuroIDCore._isTesting = true
        NeuroIDCore.shared.datastore = dataStore
        NeuroIDCore.shared.identifierService = mockIdentifierService

        mockedNetworkService = MockNetworkService()
        mockedNetworkService.mockResponse = try! JSONEncoder().encode(RemoteConfiguration.mock())
        mockedNetworkService.mockResponseResult = RemoteConfiguration.mock()
        NeuroIDCore.shared.networkService = mockedNetworkService
    }

    override func tearDown() {
        _ = NeuroID.stop()

        mockedNetworkService.resetMockCounts()
        // Clear out the DataStore Events after each test
        clearOutDataStore()
        NeuroIDCore._isTesting = false
    }

    func test_getAdvDeviceLatency() {
        let mockService = MockDeviceSignalService()
        NeuroIDCore.shared.deviceSignalService = mockService
        let configuration = NeuroID.Configuration(clientKey: "key_test_0OMmplsawAp2CQfWrytWA3wL")
        _ = NeuroID.configure(configuration)
        let randomTimeInMilliseconds = Double(Int.random(in: 0 ..< 3000))
        mockService.mockResult = .success(("empty mock result. Can be filled with anything", randomTimeInMilliseconds, nil))

        NeuroIDCore.shared.configService = MockConfigService()

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
        NeuroIDCore.shared.clientKey = nil
        UserDefaults.standard.setValue(nil, forKey: clientKeyKey)
        UserDefaults.standard.setValue("testTabId", forKey: tabIdKey)

        let configuration = NeuroID.Configuration(
            clientKey: clientKey,
            isAdvancedDevice: false
        )
        let configured = NeuroID.configure(configuration)
        assert(configured)

        let clientKeyValue = UserDefaults.standard.string(forKey: clientKeyKey)
        assert(clientKeyValue == clientKey)

        let tabIdValue = UserDefaults.standard.string(forKey: tabIdKey)
        assert(tabIdValue == nil)

        assertStoredEventCount(type: "CREATE_SESSION", count: 0)

        assert(NeuroIDCore.shared.environment == "\(Constants.environmentLive.rawValue)")
        
        // Wait for async config fetch to complete by checking cacheSetWithRemote
        let exp = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                guard let realConfig = NeuroIDCore.shared.configService as? ConfigService else { return false }
                return realConfig.cacheSetWithRemote
            },
            object: nil
        )
        wait(for: [exp], timeout: 4.0)
        
        assert(mockedNetworkService.fetchRemoteConfigSuccessCount == 1)
        assert(mockedNetworkService.fetchRemoteConfigFailureCount == 0)
    }

    func test_configure_invalidKey() {
        clearOutDataStore()
        // remove things configured in setup
        NeuroIDCore.shared.environment = Constants.environmentTest.rawValue
        NeuroIDCore.shared.clientKey = nil
        UserDefaults.standard.setValue(nil, forKey: clientKeyKey)
        UserDefaults.standard.setValue("testTabId", forKey: tabIdKey)

        let configuration = NeuroID.Configuration(clientKey: "invalid_key", isAdvancedDevice: false)
        let configured = NeuroID.configure(configuration)
        assert(configured == false)

        let clientKeyValue = UserDefaults.standard.string(forKey: clientKeyKey)
        assert(clientKeyValue == nil)

        let tabIdValue = UserDefaults.standard.string(forKey: tabIdKey)
        assert(tabIdValue == "testTabId-invalid-client-key")

        assertStoredEventCount(type: "CREATE_SESSION", count: 0)

        // 1 Log event should be in queue if the key fails validation
        assertQueuedEventTypeAndCount(type: "LOG", count: 1)

        assert(NeuroIDCore.shared.environment == "\(Constants.environmentTest.rawValue)")
    }

    func test_start_failure() {
        tearDown()
        NeuroIDCore.shared._isSDKStarted = false
        NeuroIDCore.shared.configService = MockConfigService()
        NeuroIDCore.shared.clientKey = nil

        // pre tests
        assert(!NeuroIDCore.shared.isSDKStarted)
        assert(NeuroIDCore.shared.clientKey == nil)

        // action
        NeuroID.start { started in
            assert(!started)
            // post action test
            assert(!NeuroIDCore.shared.isSDKStarted)
        }
    }

    func test_start_success() {
        tearDown()
        NeuroIDCore.shared._isSDKStarted = false
        NeuroIDCore.shared.configService = MockConfigService()
        NeuroIDCore._isTesting = true
//        NeuroID.isAdvancedDevice = false

        // pre tests
        assert(!NeuroIDCore.shared.isSDKStarted)

        // action
        NeuroID.start { started in
            // post action test
            assert(started)
            assert(NeuroIDCore.shared.isSDKStarted)
            self.assertStoredEventCount(type: "CREATE_SESSION", count: 1)
            self.assertStoredEventCount(type: "MOBILE_METADATA_IOS", count: 1)

            NeuroIDCore._isTesting = false
        }
    }

    func test_start_success_queuedEvent() {
        _ = NeuroID.stop()
        NeuroIDCore.shared._isSDKStarted = false
        NeuroIDCore.shared.configService = MockConfigService()
        NeuroIDCore._isTesting = true

        // pre tests
        assert(!NeuroIDCore.shared.isSDKStarted)

        clearOutDataStore()

        // action
        NeuroID.start { started in
            // post action test
            assert(started)
            assert(NeuroIDCore.shared.isSDKStarted)

            self.assertStoredEventCount(type: "CREATE_SESSION", count: 1)
            self.assertStoredEventCount(type: "MOBILE_METADATA_IOS", count: 1)
            self.assertStoredEventCount(type: "APPLICATION_METADATA", count: 1)
            self.assertStoredEventCount(type: "LOG", count: 2)
            NeuroIDCore._isTesting = false
        }
    }

    func test_stop() {
        NeuroIDCore.shared._isSDKStarted = true
        assert(NeuroIDCore.shared.isSDKStarted)

        let stopped = NeuroID.stop()
        assert(stopped)
        assert(!NeuroIDCore.shared.isSDKStarted)
    }

    func test_getSDKVersion() {
        let resultAdvTrue = NeuroID.getSDKVersion()
        assert(resultAdvTrue.contains("-adv"))

        NeuroIDCore.shared.isRN = true
        let resultRNTrue = NeuroID.getSDKVersion()
        assert(resultRNTrue.contains("-rn"))

        NeuroIDCore.shared.isRN = false
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
