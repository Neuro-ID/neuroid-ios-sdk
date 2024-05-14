//
//  NIDConfigService.swift
//  NeuroID

import Alamofire
import Foundation

class NIDConfigService {
    static let DEFAULT_SAMPLE_RATE: Int = 100
    static var NID_CONFIG_URL = "https://scripts.neuro-id.com/mobile/"
    
    var networkService: NIDNetworkServiceProtocol

    var cacheSetWithRemote = false
    var cacheCreationTime: Date = .init()

    public var configCache: ConfigResponseData = .init()
    
    init(networkService: NIDNetworkServiceProtocol = NeuroID.networkService) {
        self.networkService = networkService
    }
    
    func retrieveConfig(completion: @escaping () -> Void) {
        if !NeuroID.verifyClientKeyExists() {
            cacheSetWithRemote = false
            completion()
            return
        }
        
        let config_url = NIDConfigService.NID_CONFIG_URL + NeuroID.clientKey! + ".json"
        networkService.getRequest(
            url: URL(string: config_url)!,
            responseDecodableType: ConfigResponseData.self
        ) { response in
            switch response.result {
            case .success(let responseData):
                self.setCache(responseData)
                NIDLog.d("Retrieved remote config")
                
                self.cacheSetWithRemote = true
                self.cacheCreationTime = .init()
                completion()
            case .failure(let error):
                NIDLog.e("Failed to retrieve NID Config \(error)")
                self.configCache = ConfigResponseData()
                self.cacheSetWithRemote = false
                completion()
            }
        }
    }
    
    func setCache(_ newCache: ConfigResponseData) {
        configCache = newCache
    }
    
    func expiredCache() -> Bool {
        if !cacheSetWithRemote {
            return true
        }
        // 5 min is the default, can be updated later
        let TTLTime = Calendar.current.date(byAdding: .minute, value: -5, to: Date())!
        
        return cacheCreationTime < TTLTime
    }
    
    func retrieveOrRefreshCache(completion: @escaping () -> Void) {
        if expiredCache() {
            retrieveConfig {
                completion()
            }
        } else {
            completion()
        }
    }
    
    func updateConfigOptions(siteID: String? = nil, completion: @escaping () -> Void) {
        // check cache time
        retrieveOrRefreshCache {
            // retrieve the site config for the site
            
            // if siteID == config.siteID - then use top level value
            // if siteID == nil then assume parent site
            if NeuroID.isCollectionSite(siteID: siteID) {
                self.configCache.currentSampleRate = self.configCache.sampleRate ?? NIDConfigService.DEFAULT_SAMPLE_RATE
                completion()
                return
            }
            
            // get linked site options and override config
            let linkedSiteConfig = self.configCache.linkedSiteOptions?[siteID ?? ""]
            if linkedSiteConfig == nil {
                self.configCache.currentSampleRate = NIDConfigService.DEFAULT_SAMPLE_RATE
            } else if linkedSiteConfig != nil {
                self.configCache.currentSampleRate = linkedSiteConfig?.sampleRate ?? NIDConfigService.DEFAULT_SAMPLE_RATE
            }
            
            completion()
        }
    }
}
