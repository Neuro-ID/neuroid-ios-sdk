//
//  ConfigServiceTests.swift
//  SDKTest
//

import Foundation
import Testing

@testable import NeuroID

@Suite
struct ConfigServiceTests {

    var networkService: MockNetworkService
    var configService: ConfigService

    init() {
        ConfigService.NID_CONFIG_URL = "https://scripts.neuro-dev.com/mobile/"
        NeuroIDCore.shared.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"

        self.networkService = MockNetworkService()
        self.configService = ConfigService(
            networkService: networkService
        )
    }

    // Valid key, fetch request failed
    @Test
    mutating func retrieveConfigKeyNoInternet() async {
        // Set up new config service with mocked network service
        networkService.mockRequestShouldFail = true

        // set an initial config to test that it was set to the default one
        let newCache = RemoteConfiguration(
            callInProgress: false,
            geoLocation: false,
            eventQueueFlushInterval: 0,
            eventQueueFlushSize: 1999,
            requestTimeout: 0,
            gyroAccelCadence: true,
            gyroAccelCadenceTime: 0
        )
        configService.setConfigCache(newCache)

        await configService.retrieveConfig()

        // defaults to default remote config on failure
        #expect(configService.configCache == RemoteConfiguration())
        #expect(!configService.cacheSetWithRemote)
    }

    // Invalid key, no fetch request
    @Test
    func retrieveConfigInvalidKey() async {
        // override key to empty
        NeuroIDCore.shared.clientKey = ""
        await configService.retrieveConfig()

        // Remote config should not have been fetched, therefore still expired
        #expect(configService.cacheExpired)
        #expect(!configService.cacheSetWithRemote)

        #expect(configService.configCache.requestTimeout == 10)
        #expect(!configService.configCache.geoLocation)
    }

    // Valid key, fetch request succeed
    @Test
    func retrieveConfigValidKey() async {
        networkService.mockResponseResult = RemoteConfiguration(
            callInProgress: false,
            requestTimeout: 10,
            gyroAccelCadence: true,
            gyroAccelCadenceTime: 200,
            advancedCookieExpiration: 43200
        )
        
        await configService.retrieveConfig()

        // Remote config should have been fetched, therefore not expired
        #expect(!configService.cacheExpired)
        #expect(configService.cacheSetWithRemote)
        #expect(configService.configCache != RemoteConfiguration())
    }

    @Test(arguments: [true, false])
    func expiredCache(cacheSetWithRemote: Bool) {
        configService.cacheSetWithRemote = cacheSetWithRemote
        #expect(configService.cacheExpired == !cacheSetWithRemote)
    }

    // TODO: Add coverage for other non-nil siteIDs
    @Test
    func updateIsSampledStatusNilSiteID() {
        configService._isSessionFlowSampled = false
        configService.updateIsSampledStatus(siteID: nil)
        #expect(configService.isSessionFlowSampled)
    }

    @Test(arguments: [
        // Roll 0
        Rolls(
            mockedRandomGenerator: MockedNIDRandomGenerator(0),
            shouldFail: false,
            expectedResults: [
                "test0": false,
                "test10": true,
                "test30": true,
                "test50": true,
                "test100": true
            ],
            siteIDMapIsEmpty: false
        ),

        // Roll 30
        Rolls(
            mockedRandomGenerator: MockedNIDRandomGenerator(30),
            shouldFail: false,
            expectedResults: [
                "test0": false,
                "test10": false,
                "test30": true,
                "test50": true,
                "test100": true
            ],
            siteIDMapIsEmpty: false
        ),

        // Roll 50
        Rolls(
            mockedRandomGenerator: MockedNIDRandomGenerator(50),
            shouldFail: false,
            expectedResults: [
                "test0": false,
                "test10": false,
                "test30": false,
                "test50": true,
                "test100": true
            ],
            siteIDMapIsEmpty: false
        ),

        // Roll 100
        Rolls(
            mockedRandomGenerator: MockedNIDRandomGenerator(100),
            shouldFail: false,
            expectedResults: [
                "test0": false,
                "test10": false,
                "test30": false,
                "test50": false,
                "test100": true
            ],
            siteIDMapIsEmpty: false
        ),

        // Roll Failure
        Rolls(
            mockedRandomGenerator: MockedNIDRandomGenerator(0),
            shouldFail: true,
            expectedResults: [
                "test0": true,
                "test10": true,
                "test30": true,
                "test50": true,
                "test100": true
            ],
            siteIDMapIsEmpty: true
        )
    ])
    mutating func configResponseProcessing(_ parms: Rolls) async {
        // setup mock network service
        networkService.mockRequestShouldFail = parms.shouldFail
        networkService.mockResponse = try! JSONEncoder().encode(RemoteConfiguration.mock())
        networkService.mockResponseResult = RemoteConfiguration.mock()

        self.configService = ConfigService(
            networkService: networkService,
            randomGenerator: parms.mockedRandomGenerator
        )

        // should start with an empty map
        #expect(configService.siteIDMap.isEmpty)

        // retrieve and process remote config
        await self.configService.retrieveConfig()

        for key in parms.expectedResults.keys {
            configService.updateIsSampledStatus(siteID: key)
            #expect(configService.isSessionFlowSampled == parms.expectedResults[key])
        }
        #expect(configService.siteIDMap.isEmpty == parms.siteIDMapIsEmpty)

        // test for a siteID not found in siteIDMap
        configService.updateIsSampledStatus(siteID: "test1000")
        #expect(configService.isSessionFlowSampled == true)
    }

    // Check that the callback runs on network request success & failure
    @Test(arguments: [true, false])
    mutating func configRetrievalCallback(shouldFail: Bool) async {
        // local var to test if changed on callback
        var configCallBackCalled = false

        // setup mock network service
        networkService.mockRequestShouldFail = shouldFail
        if !shouldFail {
            networkService.mockResponseResult = RemoteConfiguration(
                callInProgress: false,
                requestTimeout: 10,
                gyroAccelCadence: true,
                gyroAccelCadenceTime: 200,
                advancedCookieExpiration: 43200
            )
        }

        configService = ConfigService(
            networkService: networkService,
            configRetrievalCallback: { configCallBackCalled = true }
        )

        // try to retrieve config
        await configService.retrieveConfig()

        // should be true
        #expect(configCallBackCalled)
    }
}

extension ConfigServiceTests {
    // Argument Struct for Tests
    struct Rolls: CustomStringConvertible {
        let mockedRandomGenerator: RandomGenerator
        let shouldFail: Bool
        let expectedResults: [String: Bool]
        let siteIDMapIsEmpty: Bool

        // Computed Description for Testing
        var description: String {
            let count = mockedRandomGenerator.getNumber()
            return "\(shouldFail ? "Failure" : "Success") Config Response Processing Roll \(count)"
        }
    }
}

class MockedNIDRandomGenerator: RandomGenerator {
    var number: Int

    init(_ number: Int) {
        self.number = number
    }

    func getNumber() -> Int {
        return number
    }
}
