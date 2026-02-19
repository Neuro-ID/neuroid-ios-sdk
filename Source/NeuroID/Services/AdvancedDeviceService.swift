//
//  AdvancedDeviceService.swift
//  NeuroID
//
//  Created by Kevin Sites on 1/27/25.
//

import FingerprintPro
import Foundation

// Reusable tuple for Advanced Device Results (requestId, calculated duration in ms, sealedResult)
typealias AdvancedDeviceResult = (requestId: String, duration: Double, sealedResult: String?)

struct NIDADVKeyResponse: Codable {
    let key: String
}

protocol AdvancedDeviceServiceProtocol {
    func getAdvancedDeviceSignal(
        _ apiKey: String,
        clientID: String?,
        linkedSiteID: String?,
        advancedDeviceKey: String?,
        completion: @escaping (Result<AdvancedDeviceResult, Error>) -> Void
    )
}

class AdvancedDeviceService: NSObject, AdvancedDeviceServiceProtocol {
    public func getAdvancedDeviceSignal(
        _ apiKey: String,
        clientID: String?,
        linkedSiteID: String?,
        advancedDeviceKey: String?,
        completion: @escaping (Result<AdvancedDeviceResult, Error>) -> Void
    ) {
        // normalize empty advanced device keys to nil for use below
        var advKey = advancedDeviceKey
        if advKey != nil && advKey == "" {
            advKey = nil
        }
        guard let notNilFPJSKey = advKey else {
            // FPJS key not passed in, Retrieve Key from NID Server for Request
            AdvancedDeviceService.getAPIKey(
                apiKey,
                clientID: clientID,
                linkedSiteID: linkedSiteID
            ) { result in
                switch result {
                case .success(let fAPiKey):
                    // Retrieve ADV Data using Request Key
                    AdvancedDeviceService.retryAPICall(apiKey: fAPiKey, maxRetries: 3, delay: 2, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            return
        }

        // fpjs key passed in, get RID!
        AdvancedDeviceService.retryAPICall(apiKey: notNilFPJSKey, maxRetries: 3, delay: 2, completion: completion)
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
        let task = URLSession.shared.dataTask(with: apiURL) { data, response, error in
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
    
    static func getAdvancedDeviceResult(
        _ apiKey: String,
        completion: @escaping (Result<(String, String?), Error>) -> Void
    ) {
        let configuration = FingerprintPro.Configuration(
            apiKey: apiKey,
            region: endpoint(useProxy: NeuroIDCore.shared.useAdvancedDeviceProxy)
        )
        
        let client = FingerprintProFactory.getInstance(configuration)
        
        var metadata = Metadata()
        metadata.setTag(NeuroIDCore.shared.getClientID(), forKey: "clientId")
        metadata.setTag(NeuroIDCore.shared.getClientKey(), forKey: "collectorKey")
        metadata.setTag((Date().timeIntervalSince1970 * 1000).rounded(), forKey: "requestStartTime")
               
        client.getVisitorIdResponse(metadata) { result in
            switch result {
            case .success(let fpResponse):
                completion(.success((fpResponse.requestId, fpResponse.sealedResult)))
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
    
    // Selects the endpoint to use based on the `useAdvancedDeviceProxy` flag
    static func endpoint(useProxy: Bool) -> FingerprintPro.Region {
        return useProxy
            ? .custom(domain: Endpoints.proxy.url, fallback: [Endpoints.standard.url])
            : .custom(domain: Endpoints.standard.url)
    }
    
    static func retryAPICall(
        apiKey: String,
        maxRetries: Int,
        delay: TimeInterval,
        completion: @escaping (Result<AdvancedDeviceResult, Error>) -> Void
    ) {
        var currentRetry = 0

        func attemptAPICall() {
            let startTime = Date()

            getAdvancedDeviceResult(apiKey) { result in
                switch result {
                case .success(let (requestID, sealedResults)):
                    let duration = Date().timeIntervalSince(startTime) * 1000
                    completion(.success((requestID, duration, sealedResults)))

                case .failure(let error):
                    if error.localizedDescription.contains("Method not available") {
                        completion(.failure(error))
                    } else if currentRetry < maxRetries {
                        currentRetry += 1
                        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                            attemptAPICall()
                        }
                    } else {
                        completion(.failure(error))
                    }
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
