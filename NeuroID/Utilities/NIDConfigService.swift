//
//  NIDConfigService.swift
//  NeuroID

import Alamofire
import Foundation

class NIDConfigService {
    static let DEFAULT_SAMPLE_RATE: Double = 100
    static var NID_CONFIG_URL = "https://scripts.neuro-dev.com/mobile/"
    
    var networkService: NIDNetworkServiceProtocol

    var cacheSetWithRemote = false
    var cacheCreationTime: Date = .init()

    public var configCache: ConfigResponseData = .init()
    
    init(networkService: NIDNetworkServiceProtocol = NeuroID.networkService) {
        self.networkService = networkService
    }
    
    func retrieveConfig(completion: @escaping (Bool) -> Void) {
        if !NeuroID.verifyClientKeyExists() {
            cacheSetWithRemote = false
            completion(true)
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
                completion(true)
            case .failure(let error):
                NIDLog.e("Failed to retrieve NID Config \(error)")
                self.configCache = ConfigResponseData()
                self.cacheSetWithRemote = false
                completion(true)
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
            retrieveConfig { _ in
                completion()
            }
        } else {
            completion()
        }
    }
    
    func updateConfigOptions(siteID: String? = nil) {
        // check cache time
        retrieveOrRefreshCache {
            // retrieve the site config for the site
            
            // if siteID == config.siteID - then use top level value
            // if siteID == nil then assume parent site
            if siteID == nil || siteID ?? "" == self.configCache.siteID ?? "noID" {
                self.configCache.currentSampleRate = self.configCache.sampleRate ?? NIDConfigService.DEFAULT_SAMPLE_RATE
                return
            }
            
            // get linked site options and override config
            let linkedSiteConfig = self.configCache.linkedSiteOptions?[siteID ?? ""]
            if linkedSiteConfig == nil {
                self.configCache.currentSampleRate = NIDConfigService.DEFAULT_SAMPLE_RATE
            } else if linkedSiteConfig != nil {
                self.configCache.currentSampleRate = linkedSiteConfig?.sampleRate ?? NIDConfigService.DEFAULT_SAMPLE_RATE
            }
        }
    }
}
