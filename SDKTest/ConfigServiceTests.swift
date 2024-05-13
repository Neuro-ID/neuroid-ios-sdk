//
//  ConfigServiceTests.swift
//  SDKTest
//
//  Created by Clayton Selby on 4/9/24.
//
@testable import NeuroID
import XCTest

class ConfigServiceTests: XCTestCase {
    var configService = NIDConfigService()
    
    override func setUpWithError() throws {
        NIDConfigService.NID_CONFIG_URL = "https://scripts.neuro-dev.com/mobile/"
        configService = NIDConfigService()
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }
    
    func clearOutDataStore() {
        DataStore.removeSentEvents()
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
        
        configService.retrieveConfig {
            assert(self.configService.configCache.eventQueueFlushInterval != 0)
            assert(self.configService.configCache.gyroAccelCadenceTime != 0)
            assert(self.configService.configCache.eventQueueFlushSize != 1999)
            assert(self.configService.configCache.requestTimeout != 0)
            assert(!self.configService.cacheSetWithRemote)
        }
    }
    
    func test_retrieveConfig_withNoKey() throws {
        NeuroID.clientKey = ""
        
        NeuroID.networkService = NIDNetworkServiceTestImpl()
        
        configService.configCache.requestTimeout = 0
        configService.cacheSetWithRemote = true
        
        configService.retrieveConfig {
            assert(self.configService.configCache.requestTimeout == 0)
            assert(!self.configService.cacheSetWithRemote)
        }
    }
    
    func test_retrieveConfig_withKeyAndInternet() throws {
        NeuroID.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"
        
        configService.configCache.eventQueueFlushInterval = 0
        configService.configCache.callInProgress = false
        configService.configCache.geoLocation = false
        configService.configCache.gyroAccelCadence = true
        configService.configCache.gyroAccelCadenceTime = 0
        configService.configCache.requestTimeout = 0
        
        configService.retrieveConfig {
            assert(self.configService.configCache.eventQueueFlushInterval != 0)
            assert(self.configService.configCache.gyroAccelCadenceTime != 0)
            assert(self.configService.configCache.requestTimeout != 0)
            assert(self.configService.cacheSetWithRemote)
        }
    }
    
    func test_setCache() {
        configService.configCache.callInProgress = false
        
        let newConfig = ConfigResponseData()
        
        configService.setCache(newConfig)
        
        assert(configService.configCache.callInProgress)
    }
    
    func test_expiredCache_true_no_cache() {
        configService.cacheSetWithRemote = false
        let beginCacheTime = Date() // doesn't matter that time is now, no remote means cache is dead
        
        configService.cacheCreationTime = beginCacheTime
        
        let expired = configService.expiredCache()
        
        assert(expired)
    }
    
    func test_expiredCache_true() {
        configService.cacheSetWithRemote = true
        let beginCacheTime = Calendar.current.date(byAdding: .minute, value: -10, to: Date())!
        
        configService.cacheCreationTime = beginCacheTime
        
        let expired = configService.expiredCache()
        
        assert(expired)
    }

    func test_expiredCache_false() {
        configService.cacheSetWithRemote = true
        let beginCacheTime = Date()
        
        configService.cacheCreationTime = beginCacheTime
        
        let expired = configService.expiredCache()
        
        assert(!expired)
    }
    
    // Skipping tests for retrieveOrRefreshCache because it is a wrapper function for
    //  expiredCache and retrieveConfig
    
    func test_updateConfigOptions_parent_site() {
        setupKeyAndMockInternet()
        
        // Have Cache be valid
        configService.cacheSetWithRemote = true
        
        // set sample rate to validate
        configService.configCache.currentSampleRate = 2
        configService.configCache.sampleRate = 1
        
        configService.updateConfigOptions()
        
        assert(configService.configCache.currentSampleRate == 1)
    }
    
    func test_updateConfigOptions_parent_site_default() {
        setupKeyAndMockInternet()
        
        // Have Cache be valid
        configService.cacheSetWithRemote = true
        
        // set sample rate to validate
        configService.configCache.sampleRate = nil
        configService.configCache.currentSampleRate = 2
        
        configService.updateConfigOptions()
        
        assert(configService.configCache.currentSampleRate == NIDConfigService.DEFAULT_SAMPLE_RATE)
    }
    
    func test_updateConfigOptions_child_site() {
        setupKeyAndMockInternet()
        
        // Have Cache be valid
        configService.cacheSetWithRemote = true
        
        // set sample rate to validate
        configService.configCache.linkedSiteOptions?.updateValue(
            LinkedSiteOption(sampleRate: 1),
            forKey: "mySite"
        )
        configService.configCache.currentSampleRate = 2
        
        configService.updateConfigOptions(siteID: "mySite")
        
        assert(configService.configCache.currentSampleRate == 1)
    }
    
    func test_updateConfigOptions_child_site_default() {
        setupKeyAndMockInternet()
        
        // Have Cache be valid
        configService.cacheSetWithRemote = true
        
        // set sample rate to validate
       
        configService.configCache.currentSampleRate = 2
        
        configService.updateConfigOptions(siteID: "noSite")
        
        assert(configService.configCache.currentSampleRate == NIDConfigService.DEFAULT_SAMPLE_RATE)
    }
}
