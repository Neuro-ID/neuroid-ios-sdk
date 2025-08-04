//
//  NIDConfigService.swift
//  NeuroID

import Alamofire
import Foundation

protocol ConfigServiceProtocol {
    var configCache: ConfigResponseData { get }
    var siteIDMap: [String: Bool] { get }
    func clearSiteIDMap()
    func retrieveOrRefreshCache()
    var isSessionFlowSampled: Bool { get }
    func updateIsSampledStatus(siteID: String?)
}

class NIDConfigService: ConfigServiceProtocol {
    static let DEFAULT_SAMPLE_RATE: Int = 100
    static var NID_CONFIG_URL = "https://scripts.neuro-id.com/mobile/"
    static let DEFAULT_LOW_MEMORY_BACK_OFF = 5.0
    static let DEFAULT_ADV_COOKIE_EXPIRATION = 12 * 60 * 60
    
    let logger: NIDLog
    let networkService: NIDNetworkServiceProtocol
    let configRetrievalCallback: () -> Void

    var cacheSetWithRemote = false
    var cacheCreationTime: Date = .init()
    var siteIDMap: [String: Bool] = [:]
    var _isSessionFlowSampled = true
    
    var isSessionFlowSampled: Bool {
        get { _isSessionFlowSampled }
        set {}
    }
    
    public var configCache: ConfigResponseData = .init()
    
    init(
        logger: NIDLog,
        networkService: NIDNetworkServiceProtocol = NeuroID.networkService,
        configRetrievalCallback: @escaping () -> Void = {}
    ) {
        self.logger = logger
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
                self.logger.d("Retrieved remote config \(responseData)")
                self.initSiteIDSampleMap(config: responseData)
                self.cacheSetWithRemote = true
                self.cacheCreationTime = .init()
                self.captureConfigEvent(configData: responseData)
                self.configRetrievalCallback()
            case .failure(let error):
                self.logger.e("Failed to retrieve NID Config \(error)")
                self.configCache = ConfigResponseData()
                self.cacheSetWithRemote = false
                let failedRetrievalConfig = NIDEvent(type: NIDEventName.log, level: "ERROR", m: "Failed to retrieve NID config: \(error). Default values will be used.")
                NeuroID.saveEventToDataStore(failedRetrievalConfig)
                self.configRetrievalCallback()
            }
        }
    }
    
    func initSiteIDSampleMap(config: ConfigResponseData) {
        if let linkedSiteOptions: [String: LinkedSiteOption] = config.linkedSiteOptions {
            for siteID in linkedSiteOptions.keys {
                if let sampleRate: Int = linkedSiteOptions[siteID]?.sampleRate {
                    if sampleRate == 0 {
                        siteIDMap[siteID] = false
                    } else {
                        siteIDMap[siteID] = (Int.random(in: 1...100) <= sampleRate)
                    }
                }
            }
        }
        if let siteID: String = config.siteID {
            if let sampleRate: Int = config.sampleRate {
                if config.sampleRate == 0 {
                    siteIDMap[siteID] = false
                } else {
                    siteIDMap[siteID] = (Int.random(in: 1...100) <= sampleRate)
                }
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
    
    func clearSiteIDMap() {}
    
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
    
    func updateIsSampledStatus(siteID: String?) {
        if let nonNullSiteID: String = siteID {
            if let nonNullFlag = siteIDMap[nonNullSiteID] {
                print("kurt_test siteID \(nonNullSiteID) : \(nonNullFlag)")
                _isSessionFlowSampled = nonNullFlag
            }
            return
        }
        
//        let currentSampleRate = retrieveSampleRate(siteID: siteID)
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

        _isSessionFlowSampled = false
    }
}
