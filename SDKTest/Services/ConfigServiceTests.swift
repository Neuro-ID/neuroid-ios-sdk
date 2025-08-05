//
//  ConfigServiceTests.swift
//  SDKTest
//
//  Created by Clayton Selby on 4/9/24.
//
@testable import NeuroID
import XCTest

class MockedNIDRandomGenerator0: RandomGenerator {
    func getNumber() -> Int {
        return 0
    }
}

class MockedNIDRandomGenerator100: RandomGenerator {
    func getNumber() -> Int {
        return 100
    }
}

class MockedNIDRandomGenerator50: RandomGenerator {
    func getNumber() -> Int {
        return 50
    }
}

class MockedNIDRandomGenerator30: RandomGenerator {
    func getNumber() -> Int {
        return 30
    }
}

class ConfigServiceTests: XCTestCase {
    
    var configService = NIDConfigService()
    
    override func setUpWithError() throws {
        NIDConfigService.NID_CONFIG_URL = "https://scripts.neuro-dev.com/mobile/"
        configService = NIDConfigService()
    }
    
    func clearOutDataStore() {
        NeuroID.datastore.removeSentEvents()
    }
    
    func setupKeyAndMockInternet() {
        NeuroID.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"
        
        let mockedNetwork = NIDNetworkServiceTestImpl()
        mockedNetwork.mockFailedResponse()
        
        configService = NIDConfigService(networkService: mockedNetwork)
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
        NeuroID.clientKey = ""
        
        NeuroID.networkService = NIDNetworkServiceTestImpl()
        
        configService.configCache.requestTimeout = 0
        configService.cacheSetWithRemote = true
        
        configService.retrieveConfig()
        
        assert(configService.configCache.requestTimeout == 0)
        assert(!configService.cacheSetWithRemote)
        assert(!configService.configCache.geoLocation)
    }
    
    func test_retrieveConfig_withKeyAndInternet() throws {
        NeuroID.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"
        
        NeuroID.networkService = NIDNetworkServiceTestImpl()
        
        let mockedNetwork = NIDNetworkServiceTestImpl()
        mockedNetwork.mockFailedResponse()
        
        configService = NIDConfigService(networkService: mockedNetwork, configRetrievalCallback: {})
        
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
        
        let newConfig = ConfigResponseData()
        
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
    
    func test_updateIsSampledStatus_100() {
        configService.configCache.sampleRate = 100
        configService._isSessionFlowSampled = false
        
        configService.updateIsSampledStatus(siteID: nil)
        
        // ENG-8305 - Sample Status Not Updated
        assert(!configService.isSessionFlowSampled)
    }
    
    func test_updateIsSampledStatus_0() {
        configService.configCache.sampleRate = 0
        configService._isSessionFlowSampled = false
        
        configService.updateIsSampledStatus(siteID: nil)
        
        assert(!configService.isSessionFlowSampled)
    }
 
    func getResponseData() -> ConfigResponseData {
        var config: ConfigResponseData = ConfigResponseData()
        config.linkedSiteOptions = ["test0":LinkedSiteOption(sampleRate: 0),
                                    "test10":LinkedSiteOption(sampleRate: 10),
                                    "test30":LinkedSiteOption(sampleRate: 30),
                                    "test50":LinkedSiteOption(sampleRate: 50)]
        config.sampleRate = 100
        config.siteID = "test100"
        return config
    }
    
    func test_successConfigResponseProcessingRoll30() {
        NeuroID.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"
        
        let mockedData = try! JSONEncoder().encode(getResponseData())
        
        let mockedNetwork = NIDNetworkServiceTestImpl()
        mockedNetwork.mockResponse = mockedData
        mockedNetwork.mockResponseResult = getResponseData()
        mockedNetwork.shouldMockFalse = false
        
        let mockedRandomGenerator = MockedNIDRandomGenerator30()
        
        configService = NIDConfigService(networkService: mockedNetwork,
                                         randomGenerator: mockedRandomGenerator,
                                         configRetrievalCallback: {})
        
        assert(configService.siteIDMap.isEmpty)
        configService.retrieveConfig()
        
        configService.configCache.eventQueueFlushInterval = 0
        configService.configCache.callInProgress = false
        configService.configCache.geoLocation = false
        configService.configCache.gyroAccelCadence = true
        configService.configCache.gyroAccelCadenceTime = 0
        configService.configCache.requestTimeout = 0
        
        configService.updateIsSampledStatus(siteID: "test0")
        assert(!configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test10")
        assert(!configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test30")
        assert(configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test50")
        assert(configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test100")
        assert(configService.isSessionFlowSampled)
    }
    
    func test_successConfigResponseProcessingRoll0() {
        NeuroID.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"
        
        let mockedData = try! JSONEncoder().encode(getResponseData())
        
        let mockedNetwork = NIDNetworkServiceTestImpl()
        
        mockedNetwork.mockResponse = mockedData
        mockedNetwork.mockResponseResult = getResponseData()
        mockedNetwork.shouldMockFalse = false
        
        let mockedRandomGenerator = MockedNIDRandomGenerator0()

        configService = NIDConfigService(networkService: mockedNetwork,
                                         randomGenerator: mockedRandomGenerator,
                                         configRetrievalCallback: {})
        
        assert(configService.siteIDMap.isEmpty)
        configService.retrieveConfig()
        
        configService.initSiteIDSampleMap(config: getResponseData())
        configService.configCache.eventQueueFlushInterval = 0
        configService.configCache.callInProgress = false
        configService.configCache.geoLocation = false
        configService.configCache.gyroAccelCadence = true
        configService.configCache.gyroAccelCadenceTime = 0
        configService.configCache.requestTimeout = 0
        
        configService.updateIsSampledStatus(siteID: "test0")
        assert(!configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test10")
        assert(configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test30")
        assert(configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test50")
        assert(configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test100")
        assert(configService.isSessionFlowSampled)
    }
    
    func test_successConfigResponseProcessingRoll100() {
        NeuroID.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"
        
        let mockedData = try! JSONEncoder().encode(getResponseData())
        
        let mockedNetwork = NIDNetworkServiceTestImpl()
        
        mockedNetwork.mockResponse = mockedData
        mockedNetwork.mockResponseResult = getResponseData()
        mockedNetwork.shouldMockFalse = false
        
        let mockedRandomGenerator = MockedNIDRandomGenerator100()

        configService = NIDConfigService(networkService: mockedNetwork,
                                         randomGenerator: mockedRandomGenerator,
                                         configRetrievalCallback: {})
        
        assert(configService.siteIDMap.isEmpty)
        configService.retrieveConfig()
        
        configService.configCache.eventQueueFlushInterval = 0
        configService.configCache.callInProgress = false
        configService.configCache.geoLocation = false
        configService.configCache.gyroAccelCadence = true
        configService.configCache.gyroAccelCadenceTime = 0
        configService.configCache.requestTimeout = 0
        
        configService.updateIsSampledStatus(siteID: "test0")
        assert(!configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test10")
        assert(!configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test30")
        assert(!configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test50")
        assert(!configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test100")
        assert(configService.isSessionFlowSampled)
    }
    
    func test_successConfigResponseProcessingRoll50() {
        NeuroID.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"
        
        let mockedData = try! JSONEncoder().encode(getResponseData())
        
        let mockedNetwork = NIDNetworkServiceTestImpl()
        
        mockedNetwork.mockResponse = mockedData
        mockedNetwork.mockResponseResult = getResponseData()
        mockedNetwork.shouldMockFalse = false
        
        let mockedRandomGenerator = MockedNIDRandomGenerator50()

        configService = NIDConfigService(networkService: mockedNetwork,
                                         randomGenerator: mockedRandomGenerator,
                                         configRetrievalCallback: {})
        
        assert(configService.siteIDMap.isEmpty)
        configService.retrieveConfig()
        
        configService.configCache.eventQueueFlushInterval = 0
        configService.configCache.callInProgress = false
        configService.configCache.geoLocation = false
        configService.configCache.gyroAccelCadence = true
        configService.configCache.gyroAccelCadenceTime = 0
        configService.configCache.requestTimeout = 0
        
        configService.updateIsSampledStatus(siteID: "test0")
        assert(!configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test10")
        assert(!configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test30")
        assert(!configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test50")
        assert(configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test100")
        assert(configService.isSessionFlowSampled)
    }
    
    func test_failConfigResponseProcessing() {
        NeuroID.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"
        
        let mockedData = try! JSONEncoder().encode(getResponseData())
        
        let mockedNetwork = NIDNetworkServiceTestImpl()
        
        mockedNetwork.mockResponse = mockedData
        mockedNetwork.mockResponseResult = getResponseData()
        mockedNetwork.shouldMockFalse = true
        
        let mockedRandomGenerator = MockedNIDRandomGenerator50()

        configService = NIDConfigService(networkService: mockedNetwork,
                                         randomGenerator: mockedRandomGenerator,
                                         configRetrievalCallback: {})
        
        assert(configService.siteIDMap.isEmpty)
        configService.retrieveConfig()
        
        configService.configCache.eventQueueFlushInterval = 0
        configService.configCache.callInProgress = false
        configService.configCache.geoLocation = false
        configService.configCache.gyroAccelCadence = true
        configService.configCache.gyroAccelCadenceTime = 0
        configService.configCache.requestTimeout = 0
        
        // all should be true, we failed to get config, using defaults
        assert(configService.siteIDMap.isEmpty)
        configService.updateIsSampledStatus(siteID: "test0")
        assert(configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test10")
        assert(configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test30")
        assert(configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test50")
        assert(configService.isSessionFlowSampled)
        configService.updateIsSampledStatus(siteID: "test100")
        assert(configService.isSessionFlowSampled)
    }
    
}
