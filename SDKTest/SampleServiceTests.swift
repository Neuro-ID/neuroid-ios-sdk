//
//  SampleServiceTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 5/15/24.
//

@testable import NeuroID
import XCTest

class SampleServiceTests: XCTestCase {
    var sampleService: NIDSamplingService = .init()
    let mockedConfigService = MockConfigService()
    
    let childSiteID = "form_abcde123"

    override func setUpWithError() throws {
        mockedConfigService.configCache = ConfigResponseData()
        sampleService = NIDSamplingService(configService: mockedConfigService)
    }
    
    func test_updateIsSampledStatus_100() {
        mockedConfigService.configCache.sampleRate = 100
        sampleService._isSessionFlowSampled = false
        
        sampleService.updateIsSampledStatus(siteID: nil)
        
        // ENG-8305 - Sample Status Not Updated
        assert(!sampleService.isSessionFlowSampled)
    }
    
    func test_updateIsSampledStatus_0() {
        mockedConfigService.configCache.sampleRate = 0
        sampleService._isSessionFlowSampled = false
        
        sampleService.updateIsSampledStatus(siteID: nil)
        
        assert(!sampleService.isSessionFlowSampled)
    }
    
    func test_retrieveSampleRate_parent_site() {
        mockedConfigService.configCache.sampleRate = 2
        
        let value = sampleService.retrieveSampleRate(siteID: nil)
        
        assert(value == 2)
    }
    
    func test_updateConfigOptions_parent_site_default() {
        mockedConfigService.configCache.sampleRate = nil
        
        let value = sampleService.retrieveSampleRate(siteID: nil)
        
        assert(value == NIDConfigService.DEFAULT_SAMPLE_RATE)
    }
    
    func test_updateConfigOptions_child_site() {
        mockedConfigService.configCache.linkedSiteOptions?.updateValue(
            LinkedSiteOption(sampleRate: 10),
            forKey: childSiteID
        )
        
        let value = sampleService.retrieveSampleRate(siteID: childSiteID)
        
        assert(value == 10)
    }
    
    func test_updateConfigOptions_child_site_default() {
        let value = sampleService.retrieveSampleRate(siteID: childSiteID)
        
        assert(value == NIDConfigService.DEFAULT_SAMPLE_RATE)
    }
}
