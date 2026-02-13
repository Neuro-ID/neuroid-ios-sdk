//
//  UtilFunctions.swift
//  NeuroID
//
//  Created by Kevin Sites on 9/3/25.
//

import Foundation
@testable import NeuroID

func getMockResponseData() -> RemoteConfiguration {
    return RemoteConfiguration(
        sampleRate: 100,
        siteID: "test100",
        linkedSiteOptions: [
            "test0": RemoteConfiguration.LinkedSiteOption(sampleRate: 0),
            "test10": RemoteConfiguration.LinkedSiteOption(sampleRate: 10),
            "test30": RemoteConfiguration.LinkedSiteOption(sampleRate: 30),
            "test50": RemoteConfiguration.LinkedSiteOption(sampleRate: 50),
        ]
    )
}

func getMockConfigService(shouldFail: Bool, randomGenerator: RandomGenerator) -> ConfigService {
    NeuroID.shared.clientKey = "key_test_ymNZWHDYvHYNeS4hM0U7yLc7"

    let mockedData = try! JSONEncoder().encode(getMockResponseData())

    let mockedNetwork = MockNetworkService()
    mockedNetwork.mockResponse = mockedData
    mockedNetwork.mockResponseResult = getMockResponseData()
    mockedNetwork.mockRequestShouldFail = shouldFail

    let configService = ConfigService(
        networkService: mockedNetwork,
        randomGenerator: randomGenerator,
        configRetrievalCallback: {}
    )
    return configService
}
