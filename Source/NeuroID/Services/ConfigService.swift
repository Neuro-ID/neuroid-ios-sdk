//
//  ConfigService.swift
//  NeuroID
//

import Foundation

protocol ConfigServiceProtocol {
    var configCache: RemoteConfiguration { get }
    var isSessionFlowSampled: Bool { get }

    func clearSiteIDMap()
    func retrieveOrRefreshCache()
    func updateIsSampledStatus(siteID: String?) async
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

actor ConfigStore {
    var siteIDMap: [String: Bool] = [:]

    func setSiteIDMap(_ map: [String: Bool]) {
        siteIDMap = map
    }

    func clearSiteIDMap() {
        siteIDMap.removeAll()
    }

    func flag(for siteID: String) -> Bool? {
        siteIDMap[siteID]
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
    private let configStore: ConfigStore = ConfigStore()

    let configRetrievalCallback: () -> Void

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
            self.cacheSetWithRemote = true

            await self.initSiteIDSampleMap(config: config)
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

    // Access to the siteIDMap state inside the actor
    func siteIDMap() async -> [String: Bool] {
        await self.configStore.siteIDMap
    }

    private func initSiteIDSampleMap(config: RemoteConfiguration) async {
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

        await self.configStore.setSiteIDMap(newMap)

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
        // Clear siteID Map in background
        Task { await configStore.clearSiteIDMap() }
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

    func updateIsSampledStatus(siteID: String?) async {
        if let siteID: String = siteID, let flag = await configStore.flag(for: siteID) {
            self._isSessionFlowSampled = flag
            NeuroID.shared.saveEventToDataStore(
                NIDEvent(
                    type: NIDEventName.updateIsSampledStatus,
                    m: "\(siteID) : \(flag)",
                    level: "INFO"
                )
            )
            return
        }

        self._isSessionFlowSampled = true
        NeuroID.shared.saveEventToDataStore(
            NIDEvent(
                type: NIDEventName.updateIsSampledStatus,
                m: "\(siteID ?? "unknownSiteID") : \(false)",
                level: "INFO"
            )
        )
    }
}
