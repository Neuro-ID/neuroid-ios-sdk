//
//  NIDSamplingService.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/15/24.
//

import Foundation

protocol NIDSamplingServiceProtocol {
    var isSessionFlowSampled: Bool { get }
    func updateIsSampledStatus(siteID: String?) -> Void
}

class NIDSamplingService: NIDSamplingServiceProtocol {
    static let MAX_SAMPLE_RATE = 100

    let configService: ConfigServiceProtocol

    var _isSessionFlowSampled = true
    var isSessionFlowSampled: Bool {
        get { _isSessionFlowSampled }
        set {}
    }

    init(configService: ConfigServiceProtocol = NeuroID.configService) {
        self.configService = configService
    }

    /**
      Determine if the session/flow should be sampled (i.e. events captured and sent)
       if not then change the _isSessionFlowSampled var
       this var will be used in the DataStore.cleanAndStoreEvent method
       and will drop events if false
     */
    func updateIsSampledStatus(siteID: String?) {
//        ENG - 8305 - Ignore updating sample logic
//
//
//        let currentSampleRate = retrieveSampleRate(siteID: siteID)
//
//        if currentSampleRate >= NIDSamplingService.MAX_SAMPLE_RATE {
//            _isSessionFlowSampled = true
//            return
//        }
//
//        let randomValue = Int.random(in: 0 ..< NIDSamplingService.MAX_SAMPLE_RATE)
//        if randomValue < currentSampleRate {
//            _isSessionFlowSampled = true
//            return
//        }
//
//        _isSessionFlowSampled = false
    }

    /**
     Encapsulates the logic to determine the sample rate for a given site
     */
    func retrieveSampleRate(siteID: String?) -> Int {
        // retrieve the site config for the site

        // if siteID == config.siteID - then use top level value
        // if siteID == nil then assume parent site
        if NeuroID.isCollectionSite(siteID: siteID) {
            return configService.configCache.sampleRate ?? NIDConfigService.DEFAULT_SAMPLE_RATE
        }

        // get linked site options and override config
        let potentialLinkedSiteConfig = configService.configCache.linkedSiteOptions?[siteID ?? ""]
        if let linkedSiteConfig = potentialLinkedSiteConfig {
            return linkedSiteConfig.sampleRate ?? NIDConfigService.DEFAULT_SAMPLE_RATE
        } else {
            return NIDConfigService.DEFAULT_SAMPLE_RATE
        }
    }
}
