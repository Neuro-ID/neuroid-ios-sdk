//
//  MockConfigService.swift
//  SDKTest
//
//  Created by Kevin Sites on 5/15/24.
//

import Foundation
@testable import NeuroID

class MockConfigService: ConfigServiceProtocol {
    var configCache: ConfigResponseData = .init()

    func retrieveOrRefreshCache(completion: @escaping () -> Void) {
        completion()
    }
}
