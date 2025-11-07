//
//  MockDeviceSignalService.swift
//  SDKTest
//
//  Created by Clayton Selby on 4/23/24.

import Foundation
@testable import NeuroID

class MockDeviceSignalService: AdvancedDeviceServiceProtocol {
    var mockResult: Result<AdvancedDeviceResult, Error>?

    func getAdvancedDeviceSignal(
        _ apiKey: String,
        clientID: String?,
        linkedSiteID: String?,
        advancedDeviceKey: String?,
        completion: @escaping (Result<AdvancedDeviceResult, Error>) -> Void
    ) {
        if let result = mockResult {
            completion(result)
        } else {
            completion(.failure(NSError(domain: "Mock", code: 0, userInfo: [NSLocalizedDescriptionKey: "No mock result set"])))
        }
    }
}
