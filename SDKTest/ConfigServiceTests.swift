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

    func testCacheWillFailIfNoKey() throws {
        _ = NIDConfigService { success in
            if success {
                assert(!NIDConfigService.cacheSet)
            }
        }
    }
    
    func testCacheWillInitWithKey() throws {
        NeuroID.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"
        _ = NIDConfigService { success in
            if success {
                assert(NIDConfigService.cacheSet)
            }
        }
        
    }
    
    func testWillSetCacheWithRemoteValues() throws {
        NeuroID.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"

        NIDConfigService.nidConfigCache.eventQueueFlushInterval = 0
        NIDConfigService.nidConfigCache.callInProgress = false
        NIDConfigService.nidConfigCache.eventQueueFlushSize = 0
        NIDConfigService.nidConfigCache.geoLocation = false
        NIDConfigService.nidConfigCache.gyroAccelCadence = true
        NIDConfigService.nidConfigCache.gyroAccelCadenceTime = 0
        NIDConfigService.nidConfigCache.requestTimeout = 0
        
        _ = NIDConfigService { success in
            if success {
                assert(NIDConfigService.cacheSet)
                assert(NIDConfigService.nidConfigCache.eventQueueFlushInterval == 5)
                assert(NIDConfigService.nidConfigCache.callInProgress)
                assert(NIDConfigService.nidConfigCache.eventQueueFlushSize == 2000)
                assert(NIDConfigService.nidConfigCache.geoLocation)
                assert(NIDConfigService.nidConfigCache.gyroAccelCadence == false)
                assert(NIDConfigService.nidConfigCache.gyroAccelCadenceTime == 200)
                assert(NIDConfigService.nidConfigCache.requestTimeout == 10)
                
            }
        }
    }
}
