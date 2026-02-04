//
//  ConfigService.swift
//  NeuroID

import Foundation

protocol ConfigServiceProtocol {
    var configCache: RemoteConfiguration { get }
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
        let num = Int.random(in: 1...ConfigService.MAX_SAMPLE_RATE)
        return num
    }
}

class ConfigService: ConfigServiceProtocol {

    static let DEFAULT_SAMPLE_RATE: Int = 100
    static let MAX_SAMPLE_RATE: Int = 100
    static var NID_CONFIG_URL = "https://scripts.neuro-id.com/mobile/"
    static let DEFAULT_LOW_MEMORY_BACK_OFF = 5.0
    static let DEFAULT_ADV_COOKIE_EXPIRATION = 12 * 60 * 60

    // Services
    let networkService: NetworkServiceProtocol
    let randomGenerator: RandomGenerator

    let configRetrievalCallback: () -> Void

    var siteIDMap: [String: Bool] = [:]

    var _isSessionFlowSampled = true
    var isSessionFlowSampled: Bool { _isSessionFlowSampled }

    // Use default remote configuration unless replaced
    public var configCache: RemoteConfiguration = .init()
    var cacheSetWithRemote = false

    init(
        networkService: NetworkServiceProtocol,
        randomGenerator: RandomGenerator = NIDRandomGenerator(),
        configRetrievalCallback: @escaping () -> Void = {}
    ) {
        self.networkService = networkService
        self.randomGenerator = randomGenerator
        self.configRetrievalCallback = configRetrievalCallback
    }

    func retrieveConfig() async {
        guard NeuroID.shared.verifyClientKeyExists() else {
            cacheSetWithRemote = false
            configRetrievalCallback()
            return
        }
        
        do {
            let configUrlStr = ConfigService.NID_CONFIG_URL + NeuroID.shared.getClientKey() + ".json"
            let configUrl = URL(string: configUrlStr)!
            
            let config = try await networkService.fetchRemoteConfig(from: configUrl)
            
            NIDLog.debug("Retrieved remote config \(config)")
            self.configCache = config
            self.initSiteIDSampleMap(config: config)
            self.cacheSetWithRemote = true
            self.captureConfigEvent(configData: config)
            self.configRetrievalCallback()
        } catch (let error) {
            NIDLog.error("Failed to retrieve NID Config \(error)")
            self.configCache = RemoteConfiguration()
            self.cacheSetWithRemote = false
            NeuroID.shared.saveEventToDataStore(
                NIDEvent.createErrorLogEvent(
                    "Failed to retrieve NID config: \(error). Default values will be used."
                )
            )
            self.configRetrievalCallback()
        }
    }

    func initSiteIDSampleMap(config: RemoteConfiguration) {
        if let linkedSiteOptions: [String: RemoteConfiguration.LinkedSiteOption] = config.linkedSiteOptions {
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

        NeuroID.shared.saveEventToDataStore(
            NIDEvent(
                type: NIDEventName.updateSampleSiteIDMap,
                level: "INFO"
            )
        )
    }

    /**
     Determines if the cache is expired.
     Expired = not loaded from the remote source at all,
     once the cache has been loaded once, we will not expire - this is subject to change
     (i.e. a time expiration approach instead)
     */
    var cacheExpired: Bool {
        return !cacheSetWithRemote
    }

    /**
     Will check if the cache is available or needs to be refreshed,
     */
    func retrieveOrRefreshCache() {
        guard cacheExpired else { return }
        Task { await retrieveConfig() }
    }

    func clearSiteIDMap() {
        siteIDMap.removeAll()
        NeuroID.shared.saveEventToDataStore(
            NIDEvent(
                type: NIDEventName.clearSampleSiteIDmap,
                level: "INFO"
            )
        )
    }

    func captureConfigEvent(configData: RemoteConfiguration) {
        let encoder = JSONEncoder()

        guard let jsonData = try? encoder.encode(configData) else { return }

        if let jsonString = String(data: jsonData, encoding: .utf8) {
            NeuroID.shared.saveEventToDataStore(
                NIDEvent(type: .configCached, v: jsonString)
            )
        } else {
            NeuroID.shared.saveEventToDataStore(
                NIDEvent.createErrorLogEvent("Failed to parse config")
            )
        }
    }

    func updateIsSampledStatus(siteID: String?) {
        if let nonNullSiteID: String = siteID {
            if let nonNullFlag = siteIDMap[nonNullSiteID] {
                _isSessionFlowSampled = nonNullFlag
                NeuroID.shared.saveEventToDataStore(
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

        NeuroID.shared.saveEventToDataStore(
            NIDEvent(
                type: NIDEventName.updateIsSampledStatus,
                m: "\(siteID ?? "unknownSiteID") : \(false)",
                level: "INFO"
            )
        )
    }
}
