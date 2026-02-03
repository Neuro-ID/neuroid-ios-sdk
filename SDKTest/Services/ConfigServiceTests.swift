//
//  ConfigServiceTests.swift
//  SDKTest
//
//  Created by Clayton Selby on 4/9/24.
//

@testable import NeuroID
import Testing
import Foundation

class MockedNIDRandomGenerator: RandomGenerator {
    var number: Int
    
    init(_ number: Int) {
        self.number = number
    }
    
    func getNumber() -> Int {
        return number
    }
}

@Suite
struct ConfigServiceTests {
    var configService: ConfigService
    
    init() {
        ConfigService.NID_CONFIG_URL = "https://scripts.neuro-dev.com/mobile/"
        configService = ConfigService(
            networkService: MockNetworkService()
        )
    }
   
    mutating func setupKeyAndMockInternet() {
        NeuroID.shared.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"
        
        let mockedNetwork = MockNetworkService()
        mockedNetwork.mockFailedResponse()
        
        self.configService = ConfigService(networkService: mockedNetwork)
    }
   
   func getMockResponseData() -> RemoteConfiguration {
       var config = RemoteConfiguration()
       config.linkedSiteOptions = [
           "test0": RemoteConfiguration.LinkedSiteOption(sampleRate: 0),
           "test10": RemoteConfiguration.LinkedSiteOption(sampleRate: 10),
           "test30": RemoteConfiguration.LinkedSiteOption(sampleRate: 30),
           "test50": RemoteConfiguration.LinkedSiteOption(sampleRate: 50)
       ]
       config.sampleRate = 100
       config.siteID = "test100"
       return config
   }
    
    func setupMockNetworkRequest(shouldFail: Bool) -> NetworkServiceProtocol {
        let mockedNetwork = MockNetworkService()
        mockedNetwork.mockResponse = try! JSONEncoder().encode(getMockResponseData())
        mockedNetwork.mockResponseResult = getMockResponseData()
        mockedNetwork.mockRequestShouldFail = shouldFail
        
        return mockedNetwork
    }

    @Test
    mutating func retrieveConfig_withKeyAndNoInternet() async {
        setupKeyAndMockInternet()
        
        configService.configCache.eventQueueFlushInterval = 0
        configService.configCache.callInProgress = false
        configService.configCache.geoLocation = false
        configService.configCache.eventQueueFlushSize = 1999
        configService.configCache.gyroAccelCadence = true
        configService.configCache.gyroAccelCadenceTime = 0
        configService.configCache.requestTimeout = 0
        configService.cacheSetWithRemote = true
        
        await configService.retrieveConfig()
        
        #expect(configService.configCache.eventQueueFlushInterval != 0)
        #expect(configService.configCache.gyroAccelCadenceTime != 0)
        #expect(configService.configCache.eventQueueFlushSize != 1999)
        #expect(configService.configCache.requestTimeout != 0)
        #expect(!configService.cacheSetWithRemote)
    }
     
    @Test
    func retrieveConfig_withNoKey() async {
        NeuroID.shared.clientKey = ""
        
        NeuroID.shared.networkService = MockNetworkService()
        
        configService.configCache.requestTimeout = 0
        configService.cacheSetWithRemote = true
        
        await configService.retrieveConfig()
        
        #expect(configService.configCache.requestTimeout == 0)
        #expect(!configService.cacheSetWithRemote)
        #expect(!configService.configCache.geoLocation)
    }
    
    @Test
    mutating func retrieveConfig_withKeyAndInternet() async {
        NeuroID.shared.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"
        
        NeuroID.shared.networkService = MockNetworkService()
        
        let mockedNetwork = MockNetworkService()
        mockedNetwork.mockFailedResponse()

        configService = ConfigService(
            networkService: mockedNetwork,
            configRetrievalCallback: {}
        )
        
        configService.configCache.eventQueueFlushInterval = 0
        configService.configCache.callInProgress = false
        configService.configCache.geoLocation = false
        configService.configCache.gyroAccelCadence = true
        configService.configCache.gyroAccelCadenceTime = 0
        configService.configCache.requestTimeout = 0
        
        await configService.retrieveConfig()
        
        #expect(configService.configCache.eventQueueFlushInterval != 0)
        #expect(configService.configCache.gyroAccelCadenceTime != 0)
        #expect(configService.configCache.requestTimeout != 0)
        #expect(!configService.cacheSetWithRemote)
    }
    
    @Test
    func setCache() {
        configService.configCache.callInProgress = false
        
        let newConfig = RemoteConfiguration()
        
        configService.configCache = newConfig
        
        #expect(configService.configCache.callInProgress)
    }

    @Test(arguments: [true, false])
    func expiredCache(cacheSetWithRemote: Bool) {
        configService.cacheSetWithRemote = cacheSetWithRemote
        #expect(configService.cacheExpired == !cacheSetWithRemote)
    }

    @Test(arguments: [0, 100])
    func updateIsSampledStatusNilSiteID(sampleRate: Int) {
        configService.configCache.sampleRate = sampleRate
        configService._isSessionFlowSampled = false
        
        configService.updateIsSampledStatus(siteID: nil)
        
        #expect(configService.isSessionFlowSampled)
    }
 
    
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
        NeuroID.shared.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"

        self.configService = ConfigService(
            networkService: setupMockNetworkRequest(shouldFail: parms.shouldFail),
            randomGenerator: parms.mockedRandomGenerator,
            configRetrievalCallback: {}
        )
        
        #expect(configService.siteIDMap.isEmpty)
        
        await self.configService.retrieveConfig()
        
        for key in parms.expectedResults.keys {
            configService.updateIsSampledStatus(siteID: key)
            #expect(configService.isSessionFlowSampled == parms.expectedResults[key])
        }
        #expect(configService.siteIDMap.isEmpty == parms.siteIDMapIsEmpty)
           
        // test siteID not found in map
        configService.updateIsSampledStatus(siteID: "test1000")
        #expect(configService.isSessionFlowSampled == true)
    }
    
    @Test(arguments: [true, false])
    mutating func configRetrievalCallback(shouldFail: Bool) async {
        var configCallBackCalled = false
        
        self.configService = ConfigService(
            networkService: setupMockNetworkRequest(shouldFail: shouldFail),
            randomGenerator: MockedNIDRandomGenerator(0),
            configRetrievalCallback: { configCallBackCalled.toggle() }
        )
        
        await self.configService.retrieveConfig()
        
        #expect(configCallBackCalled)
    }
}
