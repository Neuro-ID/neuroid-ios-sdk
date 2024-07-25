//
//  NIDConfigService.swift
//  NeuroID

import Alamofire
import Foundation

protocol ConfigServiceProtocol {
    var configCache: ConfigResponseData { get }
    func retrieveOrRefreshCache() -> Void
}

class NIDConfigService: ConfigServiceProtocol {
    static let DEFAULT_SAMPLE_RATE: Int = 100
    static var NID_CONFIG_URL = "https://scripts.neuro-id.com/mobile/"
    static let DEFAULT_LOW_MEMORY_BACK_OFF = 5.0
    
    let networkService: NIDNetworkServiceProtocol
    let configRetrievalCallback: () -> Void

    var cacheSetWithRemote = false
    var cacheCreationTime: Date = .init()
    
    public var configCache: ConfigResponseData = .init()
    
    init(
        networkService: NIDNetworkServiceProtocol = NeuroID.networkService,
        configRetrievalCallback: @escaping () -> Void = {}
    ) {
        self.networkService = networkService
        self.configRetrievalCallback = configRetrievalCallback
    }
    
    func retrieveConfig() {
        if !NeuroID.verifyClientKeyExists() {
            cacheSetWithRemote = false
            configRetrievalCallback()
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
                self.captureConfigEvent(configData: responseData)
                self.configRetrievalCallback()
            case .failure(let error):
                NIDLog.e("Failed to retrieve NID Config \(error)")
                self.configCache = ConfigResponseData()
                self.cacheSetWithRemote = false
                let failedRetrievalConfig = NIDEvent(type: NIDEventName.log, level: "ERROR", m: "Failed to retrieve NID config: \(error). Default values will be used.")
                NeuroID.saveEventToDataStore(failedRetrievalConfig)
                self.configRetrievalCallback()

            }
        }
    }
    
    func setCache(_ newCache: ConfigResponseData) {
        configCache = newCache
    }
    
    /**
        Determines if the cache is expired.
        Expired = not loaded from the remote source at all,
        once the cache has been loaded once, we will not expire - this is subject to change
        (i.e. a time expiration approach instead)
     */
    func expiredCache() -> Bool {
        if !cacheSetWithRemote {
            return true
        }
        
        return false
    }
    
    /**
     Will check if the cache is available or needs to be refreshed,
      */
    func retrieveOrRefreshCache() {
        if expiredCache() {
            retrieveConfig()
        }
    }
    
    func captureConfigEvent(configData: ConfigResponseData) {
        let encoder = JSONEncoder()
        
        guard let jsonData = try? encoder.encode(configData) else { return }
          
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            // log current config
            let cachedConfigLog = NIDEvent(sessionEvent: NIDSessionEventName.configCached)
            cachedConfigLog.v = jsonString
            NeuroID.saveEventToDataStore(cachedConfigLog)
        } else {
            let failedCachedConfig = NIDEvent(type: NIDEventName.log)
            failedCachedConfig.m = "Failed to parse config"
            failedCachedConfig.level = "ERROR"
            NeuroID.saveEventToDataStore(failedCachedConfig)
        }
    }
}
