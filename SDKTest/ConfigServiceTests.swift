//
//  ConfigServiceTests.swift
//  SDKTest
//
//  Created by Clayton Selby on 4/9/24.
//
@testable import NeuroID
import XCTest

class ConfigServiceTests: XCTestCase {
    
    override func setUpWithError() throws {
        NIDConfigService.nidURL = "https://scripts.neuro-dev.com/mobile/"
    }
    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }
    
    func clearOutDataStore() {
        DataStore.removeSentEvents()
    }
    
    func testCacheWillInitWithKey() throws {
        NeuroID.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"
        _ = NIDConfigService { success in
            if success {
                assert(NIDConfigService.cacheSetWithRemote)
            }
        }
    }
    
    func testCacheWillInitWithDefaultIfNoInternet() throws {
        NeuroID.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"
        
        NIDConfigService.nidConfigCache.eventQueueFlushInterval = 0
        NIDConfigService.nidConfigCache.callInProgress = false
        NIDConfigService.nidConfigCache.geoLocation = false
        NIDConfigService.nidConfigCache.eventQueueFlushSize = 1999
        NIDConfigService.nidConfigCache.gyroAccelCadence = true
        NIDConfigService.nidConfigCache.gyroAccelCadenceTime = 0
        NIDConfigService.nidConfigCache.requestTimeout = 0
        
        NeuroID.networkService = NIDNetworkServiceTestImpl()
        
        _ = NIDConfigService { success in
            if success {
                assert(NIDConfigService.nidConfigCache.eventQueueFlushInterval != 0)
                assert(NIDConfigService.nidConfigCache.gyroAccelCadenceTime != 0)
                assert(NIDConfigService.nidConfigCache.eventQueueFlushSize != 1999)
                assert(NIDConfigService.nidConfigCache.requestTimeout != 0)
                assert(!NIDConfigService.nidConfigCache.geoLocation)
            }
        }
    }
    
    
    func testWillSetCacheWithRemoteValues() throws {
        NeuroID.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"

        NIDConfigService.nidConfigCache.eventQueueFlushInterval = 0
        NIDConfigService.nidConfigCache.callInProgress = false
        NIDConfigService.nidConfigCache.geoLocation = false
        NIDConfigService.nidConfigCache.gyroAccelCadence = true
        NIDConfigService.nidConfigCache.gyroAccelCadenceTime = 0
        NIDConfigService.nidConfigCache.requestTimeout = 0
        
        _ = NIDConfigService { success in
            if success {
                assert(NIDConfigService.nidConfigCache.eventQueueFlushInterval != 0)
                assert(NIDConfigService.nidConfigCache.gyroAccelCadenceTime != 0)
                assert(NIDConfigService.nidConfigCache.requestTimeout != 0)
                assert(NIDConfigService.cacheSetWithRemote)
            }
        }
    }
}
