//
//  ConfigServiceTests.swift
//  SDKTest
//
//  Created by Clayton Selby on 4/9/24.
//
@testable import NeuroID
import XCTest

class MockedNIDRandomGenerator: RandomGenerator {
    var number: Int
    
    init(_ number: Int) {
        self.number = number
    }
    
    func getNumber() -> Int {
        return number
    }
}

class ConfigServiceTests: XCTestCase {
    var configService = NIDConfigService(
        logger: NIDLog(),
        networkService: MockNetworkService()
    )
    
    override func setUpWithError() throws {
        NIDConfigService.NID_CONFIG_URL = "https://scripts.neuro-dev.com/mobile/"
        configService = NIDConfigService(
            logger: NIDLog(),
            networkService: MockNetworkService()
        )
    }
    
    func clearOutDataStore() {
        NeuroID.shared.datastore.removeSentEvents()
    }
    
    func setupKeyAndMockInternet() {
        NeuroID.shared.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"
        
        let mockedNetwork = MockNetworkService()
        mockedNetwork.mockFailedResponse()
        
        configService = NIDConfigService(logger: NIDLog(), networkService: mockedNetwork)
    }
    
    func getMockResponseData() -> RemoteConfiguration {
        var config = RemoteConfiguration()
        config.linkedSiteOptions = ["test0": LinkedSiteOption(sampleRate: 0),
                                    "test10": LinkedSiteOption(sampleRate: 10),
                                    "test30": LinkedSiteOption(sampleRate: 30),
                                    "test50": LinkedSiteOption(sampleRate: 50)]
        config.sampleRate = 100
        config.siteID = "test100"
        return config
    }
    
    func setupMockNetworkRequest(shouldFail: Bool) -> NetworkServiceProtocol {
        let mockedNetwork = MockNetworkService()
        mockedNetwork.mockResponse = try! JSONEncoder().encode(getMockResponseData())
        mockedNetwork.mockResponseResult = getMockResponseData()
        mockedNetwork.shouldMockFalse = shouldFail
        
        return mockedNetwork
    }
       
    func runConfigResponseProcessing(
        mockedRandomGenerator: RandomGenerator,
        shouldFail: Bool
    ) -> NIDConfigService {
        NeuroID.shared.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"

        configService = NIDConfigService(
            logger: NIDLog(),
            networkService: setupMockNetworkRequest(shouldFail: shouldFail),
            randomGenerator: mockedRandomGenerator,
            configRetrievalCallback: {}
        )
        assert(configService.siteIDMap.isEmpty)
        configService.retrieveConfig()
        return configService
    }
        
    func evaluateConfigResponseProcessing(
        mockedRandomGenerator: RandomGenerator,
        shouldFail: Bool,
        expectedResults: [String: Bool],
        siteIDMapIsEmpty: Bool
    ) {
        let configService = runConfigResponseProcessing(
            mockedRandomGenerator: mockedRandomGenerator,
            shouldFail: shouldFail
        )
        for key in expectedResults.keys {
            configService.updateIsSampledStatus(siteID: key)
            assert(configService.isSessionFlowSampled == expectedResults[key])
        }
        assert(configService.siteIDMap.isEmpty == siteIDMapIsEmpty)
           
        // test siteID not found in map
        configService.updateIsSampledStatus(siteID: "test1000")
        assert(configService.isSessionFlowSampled == true)
    }
    
    func test_retrieveConfig_withKeyAndNoInternet() throws {
        setupKeyAndMockInternet()
        
        configService.configCache.eventQueueFlushInterval = 0
        configService.configCache.callInProgress = false
        configService.configCache.geoLocation = false
        configService.configCache.eventQueueFlushSize = 1999
        configService.configCache.gyroAccelCadence = true
        configService.configCache.gyroAccelCadenceTime = 0
        configService.configCache.requestTimeout = 0
        configService.cacheSetWithRemote = true
        
        configService.retrieveConfig()
        
        assert(configService.configCache.eventQueueFlushInterval != 0)
        assert(configService.configCache.gyroAccelCadenceTime != 0)
        assert(configService.configCache.eventQueueFlushSize != 1999)
        assert(configService.configCache.requestTimeout != 0)
        assert(!configService.cacheSetWithRemote)
    }
    
    func test_retrieveConfig_withNoKey() throws {
        NeuroID.shared.clientKey = ""
        
        NeuroID.shared.networkService = MockNetworkService()
        
        configService.configCache.requestTimeout = 0
        configService.cacheSetWithRemote = true
        
        configService.retrieveConfig()
        
        assert(configService.configCache.requestTimeout == 0)
        assert(!configService.cacheSetWithRemote)
        assert(!configService.configCache.geoLocation)
    }
    
    func test_retrieveConfig_withKeyAndInternet() throws {
        NeuroID.shared.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"
        
        NeuroID.shared.networkService = MockNetworkService()
        
        let mockedNetwork = MockNetworkService()
        mockedNetwork.mockFailedResponse()

        configService = NIDConfigService(
            logger: NIDLog(),
            networkService: mockedNetwork,
            configRetrievalCallback: {}
        )
        
        configService.configCache.eventQueueFlushInterval = 0
        configService.configCache.callInProgress = false
        configService.configCache.geoLocation = false
        configService.configCache.gyroAccelCadence = true
        configService.configCache.gyroAccelCadenceTime = 0
        configService.configCache.requestTimeout = 0
        
        configService.retrieveConfig()
        
        assert(configService.configCache.eventQueueFlushInterval != 0)
        assert(configService.configCache.gyroAccelCadenceTime != 0)
        assert(configService.configCache.requestTimeout != 0)
        assert(!configService.cacheSetWithRemote)
    }
    
    func test_setCache() {
        configService.configCache.callInProgress = false
        
        let newConfig = RemoteConfiguration()
        
        configService.setCache(newConfig)
        
        assert(configService.configCache.callInProgress)
    }
    
    func test_expiredCache_true_no_cache() {
        configService.cacheSetWithRemote = false
        
        let expired = configService.expiredCache()
        
        assert(expired)
    }

    func test_expiredCache_false() {
        configService.cacheSetWithRemote = true
        
        let expired = configService.expiredCache()
        
        assert(!expired)
    }
    
    func test_updateIsSampledStatus_100_nilSiteID() {
        configService.configCache.sampleRate = 100
        configService._isSessionFlowSampled = false
        
        configService.updateIsSampledStatus(siteID: nil)
        
        // ENG-8305 - Sample Status Not Updated
        assert(configService.isSessionFlowSampled)
    }
    
    func test_updateIsSampledStatus_0_nilSiteID() {
        configService.configCache.sampleRate = 0
        configService._isSessionFlowSampled = false
        
        configService.updateIsSampledStatus(siteID: nil)
        
        assert(configService.isSessionFlowSampled)
    }
 
    func test_successConfigResponseProcessingRoll30() {
        let expectedResults = [
            "test0": false,
            "test10": false,
            "test30": true,
            "test50": true,
            "test100": true
        ]
        evaluateConfigResponseProcessing(
            mockedRandomGenerator: MockedNIDRandomGenerator(30),
            shouldFail: false,
            expectedResults: expectedResults,
            siteIDMapIsEmpty: false
        )
    }
    
    func test_successConfigResponseProcessingRoll0() {
        let expectedResults = [
            "test0": false,
            "test10": true,
            "test30": true,
            "test50": true,
            "test100": true
        ]
        evaluateConfigResponseProcessing(
            mockedRandomGenerator: MockedNIDRandomGenerator(0),
            shouldFail: false,
            expectedResults: expectedResults,
            siteIDMapIsEmpty: false
        )
    }
    
    func test_successConfigResponseProcessingRoll100() {
        let expectedResults = [
            "test0": false,
            "test10": false,
            "test30": false,
            "test50": false,
            "test100": true
        ]
        evaluateConfigResponseProcessing(
            mockedRandomGenerator: MockedNIDRandomGenerator(100),
            shouldFail: false,
            expectedResults: expectedResults,
            siteIDMapIsEmpty: false
        )
    }
    
    func test_successConfigResponseProcessingRoll50() {
        let expectedResults = [
            "test0": false,
            "test10": false,
            "test30": false,
            "test50": true,
            "test100": true
        ]
        evaluateConfigResponseProcessing(
            mockedRandomGenerator: MockedNIDRandomGenerator(50),
            shouldFail: false,
            expectedResults: expectedResults,
            siteIDMapIsEmpty: false
        )
    }
    
    func test_failConfigResponseProcessing() {
        let expectedResults = [
            "test0": true,
            "test10": true,
            "test30": true,
            "test50": true,
            "test100": true
        ]
        evaluateConfigResponseProcessing(
            mockedRandomGenerator: MockedNIDRandomGenerator(0),
            shouldFail: true,
            expectedResults: expectedResults,
            siteIDMapIsEmpty: true
        )
    }
    
    func test_configRetrievalCallback_on_success() {
        var configCallBackCalled = false
        
        configService = NIDConfigService(
            logger: NIDLog(),
            networkService: setupMockNetworkRequest(shouldFail: false),
            randomGenerator: MockedNIDRandomGenerator(0),
            configRetrievalCallback: { configCallBackCalled.toggle() }
        )
        
        configService.retrieveConfig()
        
        assert(configCallBackCalled)
    }
    
    func test_configRetrievalCallback_on_failure() {
        var configCallBackCalled = false
        
        configService = NIDConfigService(
            logger: NIDLog(),
            networkService: setupMockNetworkRequest(shouldFail: true),
            randomGenerator: MockedNIDRandomGenerator(0),
            configRetrievalCallback: { configCallBackCalled.toggle() }
        )
        
        configService.retrieveConfig()
        
        assert(configCallBackCalled)
    }
}
