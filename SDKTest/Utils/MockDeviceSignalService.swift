//
//  MockDeviceSignalService.swift
//  SDKTest
//
//  Created by Clayton Selby on 4/23/24.
//

import Foundation
import NeuroIDAdvancedDevice
@testable import NeuroID

class MockDeviceSignalService: DeviceSignalService {
    var mockResult: Result<String, Error>?

    func getAdvancedDeviceSignal(_ apiKey: String, completion: @escaping (Result<String, Error>) -> Void) {
        if let result = mockResult {
            completion(result)
        } else {
            completion(.failure(NSError(domain: "Mock", code: 0, userInfo: [NSLocalizedDescriptionKey: "No mock result set"])))
        }
    }
}
