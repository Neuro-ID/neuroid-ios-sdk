//
//  UtilFunctions.swift
//  NeuroID
//
//  Created by Kevin Sites on 9/3/25.
//
@testable import NeuroID

func getMockResponseData() -> ConfigResponseData {
    var config = ConfigResponseData()
    config.linkedSiteOptions = [
        "test0": LinkedSiteOption(sampleRate: 0),
        "test10": LinkedSiteOption(sampleRate: 10),
        "test30": LinkedSiteOption(sampleRate: 30),
        "test50": LinkedSiteOption(sampleRate: 50),
    ]
    config.sampleRate = 100
    config.siteID = "test100"
    return config
}

func getMockConfigService(shouldFail: Bool, randomGenerator: RandomGenerator) -> NIDConfigService {
    NeuroID.shared.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"

    let mockedData = try! JSONEncoder().encode(getMockResponseData())

    let mockedNetwork = MockNetworkService()
    mockedNetwork.mockResponse = mockedData
    mockedNetwork.mockResponseResult = getMockResponseData()
    mockedNetwork.shouldMockFalse = shouldFail

    let configService = NIDConfigService(
        logger: NIDLog(),
        networkService: mockedNetwork,
        randomGenerator: randomGenerator,
        configRetrievalCallback: {}
    )
    return configService
}
