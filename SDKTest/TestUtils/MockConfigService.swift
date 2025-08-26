//
//  MockConfigService.swift
//  SDKTest
//
//  Created by Kevin Sites on 5/15/24.
//

import Foundation
@testable import NeuroID

class MockConfigService: ConfigServiceProtocol {
    var mockConfigCache: ConfigResponseData = .init()

    func resetMocks() {
        mockConfigCache = .init()
    }

    // Protocol Implementation
    var configCache: ConfigResponseData {
        mockConfigCache
    }

    func retrieveOrRefreshCache() {}
    var siteIDMap: [String: Bool] = [:]
    func clearSiteIDMap() { siteIDMap.removeAll() }
    var isSessionFlowSampled: Bool { return true }
    func updateIsSampledStatus(siteID: String?) {}
}
