//
//  ConfigService.swift
//  NeuroID
//

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

    private let inFlightLock = NSLock()
    private var inFlightRetrieveTask: Task<Void, Never>?

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
            setCacheWithRemote(false)
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
            setCacheWithRemote(true)
            self.captureConfigEvent(configData: config)
            self.configRetrievalCallback()
        } catch (let error) {
            NIDLog.error("Failed to retrieve NID Config \(error)")
            self.configCache = RemoteConfiguration()
            setCacheWithRemote(false)
            NeuroID.shared.saveEventToDataStore(
                NIDEvent.createErrorLogEvent(
                    "Failed to retrieve NID config: \(error). Default values will be used."
                )
            )
            self.configRetrievalCallback()
        }
    }

    private func initSiteIDSampleMap(config: RemoteConfiguration) {
        var newMap: [String: Bool] = [:]

        if let linkedSiteOptions: [String: RemoteConfiguration.LinkedSiteOption] = config.linkedSiteOptions {
            for (siteID, opt) in linkedSiteOptions {
                if let sampleRate: Int = opt.sampleRate {
                    newMap[siteID] = (sampleRate == 0) ? false : (randomGenerator.getNumber() <= sampleRate)
                }
            }
        }

        if let siteID: String = config.siteID, let sampleRate: Int = config.sampleRate {
            newMap[siteID] = (sampleRate == 0) ? false : (randomGenerator.getNumber() <= sampleRate)
        }

        self.siteIDMap = newMap

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
        inFlightLock.withLock {
            return !cacheSetWithRemote
        }
    }

    /**
     Will check if the cache is available or needs to be refreshed,
     */
    func retrieveOrRefreshCache() {
        inFlightLock.withLock {
            // Ensure cache has not been set and that there is not an existing task running
            guard !cacheSetWithRemote, inFlightRetrieveTask == nil else { return }
            
            let task = Task {
                defer {
                    self.inFlightLock.withLock {
                        self.inFlightRetrieveTask = nil
                    }
                }
                
                await self.retrieveConfig()
            }
            
            inFlightRetrieveTask = task
        }
    }

    private func setCacheWithRemote(_ value: Bool) {
        inFlightLock.withLock {
            cacheSetWithRemote = value
        }
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
        if let siteID: String = siteID, let flag = siteIDMap[siteID] {
            _isSessionFlowSampled = flag
            NeuroID.shared.saveEventToDataStore(
                NIDEvent(
                    type: NIDEventName.updateIsSampledStatus,
                    m: "\(siteID) : \(flag)",
                    level: "INFO"
                )
            )
            return
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
