//
//  NIDConfigService.swift
//  NeuroID

import Alamofire
import Foundation

protocol ConfigServiceProtocol {
    var configCache: ConfigResponseData { get }
    var siteIDMap: [String: Bool] { get }
    func clearSiteIDMap()
    func retrieveOrRefreshCache() -> Void
    var isSessionFlowSampled: Bool { get }
    func updateIsSampledStatus(siteID: String?) -> Void
}

protocol RandomGenerator {
    func getNumber() -> Int
}

class NIDRandomGenerator: RandomGenerator {
    func getNumber() -> Int {
        let num = Int.random(in: 1...NIDConfigService.MAX_SAMPLE_RATE)
        return num
    }
}

class NIDConfigService: ConfigServiceProtocol {
    let randomGenerator: RandomGenerator
    
    static let DEFAULT_SAMPLE_RATE: Int = 100
    static let MAX_SAMPLE_RATE: Int = 100
    static var NID_CONFIG_URL = "https://scripts.neuro-id.com/mobile/"
    static let DEFAULT_LOW_MEMORY_BACK_OFF = 5.0
    static let DEFAULT_ADV_COOKIE_EXPIRATION = 12 * 60 * 60
    
    let networkService: NIDNetworkServiceProtocol
    let configRetrievalCallback: () -> Void

    var cacheSetWithRemote = false
    var cacheCreationTime: Date = .init()
    var siteIDMap : [String: Bool] = [:]
    var _isSessionFlowSampled = true
    
    var isSessionFlowSampled: Bool {
        get { _isSessionFlowSampled }
        set {}
    }
    
    public var configCache: ConfigResponseData = .init()
    
    init(
        networkService: NIDNetworkServiceProtocol = NeuroID.networkService,
        randomGenerator: RandomGenerator = NIDRandomGenerator(),
        configRetrievalCallback: @escaping () -> Void = {}
    ) {
        self.randomGenerator = randomGenerator
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
                NIDLog.d("Retrieved remote config \(responseData)")
                self.initSiteIDSampleMap(config: responseData)
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
    
    func initSiteIDSampleMap(config: ConfigResponseData) {
        if let linkedSiteOptions: [String: LinkedSiteOption] = config.linkedSiteOptions{
            for siteID in linkedSiteOptions.keys {
                if let sampleRate: Int = linkedSiteOptions[siteID]?.sampleRate {
                    if (sampleRate == 0) {
                        siteIDMap[siteID] = false
                    } else {
                        siteIDMap[siteID] = (randomGenerator.getNumber() <= sampleRate)
                    }
                }
            }
        }
        if let siteID : String = config.siteID {
            if let sampleRate: Int = config.sampleRate {
                if (config.sampleRate == 0) {
                    siteIDMap[siteID] = false
                } else {
                    siteIDMap[siteID] = (randomGenerator.getNumber() <= sampleRate)
                }
            }
        }
        let initSiteIDMapEvent = NIDEvent(type: NIDEventName.updateSampleSiteIDMap,
                                               level: "INFO")
        NeuroID.saveQueuedEventToLocalDataStore(initSiteIDMapEvent)
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
    
    func clearSiteIDMap() {
        siteIDMap.removeAll()
        let clearSiteIDMapEvent = NIDEvent(type: NIDEventName.clearSampleSiteIDmap,
                                               level: "INFO")
        NeuroID.saveQueuedEventToLocalDataStore(clearSiteIDMapEvent)
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
    
    func updateIsSampledStatus(siteID: String?) {
        if let nonNullSiteID: String = siteID {
            if let nonNullFlag = siteIDMap[nonNullSiteID] {
                _isSessionFlowSampled = nonNullFlag
                let sampleStatusUpdateEvent = NIDEvent(type: NIDEventName.updateIsSampledStatus,
                                                       level: "INFO",  m:"\(nonNullSiteID) : \(nonNullFlag)")
                NeuroID.saveQueuedEventToLocalDataStore(sampleStatusUpdateEvent)
            }
            return
        }
        _isSessionFlowSampled = false
        
        let sampleStatusUpdateEvent = NIDEvent(type: NIDEventName.updateIsSampledStatus,
                                               level: "INFO", m:"\(siteID) : \(false)")
        NeuroID.saveQueuedEventToLocalDataStore(sampleStatusUpdateEvent)
    }
}
