//
//  AdvancedDeviceService.swift
//  NeuroID
//
//  Created by Kevin Sites on 1/27/25.
//

import FingerprintPro
import Foundation

struct NIDADVKeyResponse: Codable {
    let key: String
}

protocol AdvancedDeviceServiceProtocol {
    func getAdvancedDeviceSignal(
        _ apiKey: String, clientID: String?, linkedSiteID: String?, advancedDeviceKey: String?,
        completion: @escaping (Result<(String, Double), Error>) -> Void
    )
}

class AdvancedDeviceService: NSObject, AdvancedDeviceServiceProtocol {
    public func getAdvancedDeviceSignal(
        _ apiKey: String,
        clientID: String?,
        linkedSiteID: String?,
        advancedDeviceKey: String?,
        completion: @escaping (Result<(String, Double), Error>) -> Void
    ) {
        // normalize empty advanced device keys to nil for use below
        var advKey = advancedDeviceKey
        if advKey != nil && advKey == "" {
            advKey = nil
        }
        guard let notNilFPJSKey = advKey else {
            // FPJS key not passed in, Retrieve Key from NID Server for Request
            AdvancedDeviceService.getAPIKey(
                apiKey, clientID: clientID, linkedSiteID: linkedSiteID
            ) { result in
                switch result {
                case .success(let fAPiKey):
                    // Retrieve ADV Data using Request Key
                    AdvancedDeviceService.retryAPICall(
                        apiKey: fAPiKey, maxRetries: 3, delay: 2
                    ) { result in
                        switch result {
                        case .success(let (value, duration)):
                            completion(.success((value, duration)))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            return
        }
        // fpjs key passed in, get RID!
        AdvancedDeviceService.retryAPICall(
            apiKey: notNilFPJSKey, maxRetries: 3, delay: 2
        ) { result in
            switch result {
            case .success(let (value, duration)):
                completion(.success((value, duration)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    static func getAPIKey(
        _ apiKey: String,
        clientID: String? = "",
        linkedSiteID: String? = "",
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let apiURL = URL(
            string:
            "https://receiver.neuroid.cloud/a/\(apiKey)?clientId=\(clientID ?? "")&linkedSiteId=\(linkedSiteID ?? "")"
        )!
        let task = URLSession.shared.dataTask(with: apiURL) {
            data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 403 {
                    completion(
                        .failure(
                            createError(code: 1, description: "403")
                        )
                    )
                    return
                }

                if httpResponse.statusCode == 204 {
                    completion(
                        .failure(
                            createError(code: 8, description: "204")
                        )
                    )
                    return
                }
            }

            guard let data = data else {
                completion(
                    .failure(
                        createError(
                            code: 2,
                            description: "NeuroID API Error: No Data Received"
                        )
                    )
                )
                return
            }

            do {
                let decoder = JSONDecoder()
                let myResponse = try decoder.decode(
                    NIDADVKeyResponse.self, from: data
                )

                if let data = Data(base64Encoded: myResponse.key) {
                    if let string = String(data: data, encoding: .utf8) {
                        completion(.success(string))
                    } else {
                        completion(
                            .failure(
                                createError(
                                    code: 3,
                                    description:
                                    "NeuroID API Error: Unable to convert to string"
                                )
                            )
                        )
                    }
                } else {
                    completion(
                        .failure(
                            createError(
                                code: 4,
                                description:
                                "NeuroID API Error: Error Retrieving Data"
                            )
                        )
                    )
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }

    static func getRequestID(
        _ apiKey: String,
        endpointOverride: FingerprintEndpoint?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let primaryRate = NeuroID.shared.configService.configCache.proxyPrimaryEndpointSampleRate ?? 0
        let canaryRate = NeuroID.shared.configService.configCache.proxyRCEndpointSampleRate ?? 0
        
        // Determine which endpoint to use based on sample rates
        let endpoint = endpointOverride ?? determineEndpoint(primaryRate: primaryRate, canaryRate: canaryRate)
        
        NeuroID.shared.logger.d("Using endpoint: \(endpoint)")
        
        let region: Region = .custom(domain: endpoint.url)
        let configuration = Configuration(apiKey: apiKey, region: region)
        let client = FingerprintProFactory.getInstance(configuration)
        
        client.getVisitorIdResponse { result in
            switch result {
            case .success(let fResponse):
                completion(.success(fResponse.requestId))
            case .failure(let error):
                completion(
                    .failure(
                        createError(
                            code: 6,
                            description:
                            "Fingerprint Response Failure (code 6): \(error.localizedDescription)"
                        )
                    )
                )
            }
        }
    }
    
    static func determineEndpoint(primaryRate: Int, canaryRate: Int) -> FingerprintEndpoint {
        // If both rates are zero, use default endpoint
        if primaryRate == 0 && canaryRate == 0 {
            return .standard
        }
        
        let randomValue = Int.random(in: 1...100)
        
        // Primary takes priority (capped at 100%)
        let effectivePrimaryRate = min(primaryRate, 100)
        if randomValue <= effectivePrimaryRate {
            return .primaryProxy
        }
        
        // Canary gets remaining capacity
        let canaryThreshold = effectivePrimaryRate + min(canaryRate, 100 - effectivePrimaryRate)
        if randomValue <= canaryThreshold {
            return .canaryProxy
        }
        
        // Everything else goes to default
        return .standard
    }

    static func retryAPICall(
        apiKey: String,
        maxRetries: Int,
        delay: TimeInterval,
        completion: @escaping (Result<(String, TimeInterval), Error>) -> Void
    ) {
        var currentRetry = 0

        func attemptAPICall(endpointOverride: FingerprintEndpoint? = nil) {
            let startTime = Date()

            getRequestID(apiKey, endpointOverride: endpointOverride) { result in
                if case .failure(let error) = result {
                    if error.localizedDescription.contains("Method not available") {
                        completion(.failure(error))
                    } else if currentRetry < maxRetries {
                        currentRetry += 1
                        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                            attemptAPICall(endpointOverride: .standard)
                        }
                    } else {
                        completion(.failure(error))
                    }
                } else if case .success(let value) = result {
                    let duration = Date().timeIntervalSince(startTime) * 1000
                    completion(.success((value, duration)))
                }
            }
        }

        attemptAPICall()
    }

    static func createError(code: Int, description: String) -> NSError {
        return NSError(
            domain: "NeuroIDAdvancedDevice",
            code: code,
            userInfo: [
                NSLocalizedDescriptionKey: description
            ]
        )
    }
}

extension AdvancedDeviceService {
    
    // Options for Fingerprint endpoints
    enum FingerprintEndpoint {
        case standard, primaryProxy, canaryProxy
        
        var url: String {
            switch self {
            case .standard:
                return "https://advanced.neuro-id.com"
            case .primaryProxy:
                return "https://dn.neuroid.cloud/iynlfqcb0t"
            case .canaryProxy:
                return "https://rc.dn.neuroid.cloud/iynlfqcb0t"
            }
        }
    }
}
