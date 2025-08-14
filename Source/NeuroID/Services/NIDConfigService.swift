//
//  NIDConfigService.swift
//  NeuroID

import Alamofire
import Foundation

protocol ConfigServiceProtocol {
    var configCache: ConfigResponseData { get }
    var siteIDMap: [String: Bool] { get }
    var isSessionFlowSampled: Bool { get }
    
    func clearSiteIDMap()
    func retrieveOrRefreshCache()
    func updateIsSampledStatus(siteID: String?)
}

protocol RandomGenerator {
    func getNumber() -> Int
}

class NIDRandomGenerator: RandomGenerator {
    func getNumber() -> Int {
        let num = Int.random(in: 1 ... NIDConfigService.MAX_SAMPLE_RATE)
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
    
    let logger: LoggerProtocol
    let networkService: NetworkServiceProtocol
    let configRetrievalCallback: () -> Void

    var cacheSetWithRemote = false
    var cacheCreationTime: Date = .init()
    var siteIDMap: [String: Bool] = [:]
    var _isSessionFlowSampled = true
    
    var isSessionFlowSampled: Bool { _isSessionFlowSampled }
    
    public var configCache: ConfigResponseData = .init()
    
    init(
        logger: LoggerProtocol,
        networkService: NetworkServiceProtocol,
        randomGenerator: RandomGenerator = NIDRandomGenerator(),
        configRetrievalCallback: @escaping () -> Void = {}
    ) {
        self.logger = logger
        self.networkService = networkService
        self.randomGenerator = randomGenerator
        self.configRetrievalCallback = configRetrievalCallback
    }
    
    func retrieveConfig() {
        if !NeuroID.verifyClientKeyExists() {
            cacheSetWithRemote = false
            configRetrievalCallback()
            return
        }
        
        let config_url = NIDConfigService.NID_CONFIG_URL + NeuroID.getClientKey() + ".json"
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
                NeuroID.saveEventToDataStore(
                    NIDEvent.createErrorLogEvent(
                        "Failed to retrieve NID config: \(error). Default values will be used."
                    )
                )
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
                        siteIDMap[siteID] = (randomGenerator.getNumber() <= sampleRate)
                    }
                }
            }
        }
        if let siteID: String = config.siteID {
            if let sampleRate: Int = config.sampleRate {
                if config.sampleRate == 0 {
                    siteIDMap[siteID] = false
                } else {
                    siteIDMap[siteID] = (randomGenerator.getNumber() <= sampleRate)
                }
            }
        }

        NeuroID.saveEventToDataStore(
            NIDEvent(
                type: NIDEventName.updateSampleSiteIDMap,
                level: "INFO"
            )
        )
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
        NeuroID.saveEventToDataStore(
            NIDEvent(
                type: NIDEventName.clearSampleSiteIDmap,
                level: "INFO"
            )
        )
    }
    
    func captureConfigEvent(configData: ConfigResponseData) {
        let encoder = JSONEncoder()
        
        guard let jsonData = try? encoder.encode(configData) else { return }
          
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            NeuroID.saveEventToDataStore(
                NIDEvent(type: .configCached, v: jsonString)
            )
        } else {
            NeuroID.saveEventToDataStore(
                NIDEvent.createErrorLogEvent("Failed to parse config")
            )
        }
    }
    
    func updateIsSampledStatus(siteID: String?) {
        if let nonNullSiteID: String = siteID {
            if let nonNullFlag = siteIDMap[nonNullSiteID] {
                _isSessionFlowSampled = nonNullFlag
                NeuroID.saveEventToDataStore(
                    NIDEvent(
                        type: NIDEventName.updateIsSampledStatus,
                        m: "\(nonNullSiteID) : \(nonNullFlag)",
                        level: "INFO"
                    )
                )
                return
            }
        }
        _isSessionFlowSampled = true
        
        NeuroID.saveEventToDataStore(
            NIDEvent(
                type: NIDEventName.updateIsSampledStatus,
                m: "\(siteID ?? "unknownSiteID") : \(false)",
                level: "INFO"
            )
        )
    }
}
