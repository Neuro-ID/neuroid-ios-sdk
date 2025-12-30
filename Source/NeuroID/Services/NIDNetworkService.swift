//
//  NIDNetworkingService.swift
//  NeuroID
//
//  Created by Clayton Selby on 2/15/24.
//

import Alamofire
import Foundation

protocol NetworkServiceProtocol {
    func retryableRequest(url: URL, neuroHTTPRequest: NeuroHTTPRequest, headers: HTTPHeaders, retryCount: Int, completion: @escaping (AFDataResponse<Data>) -> Void)
    
    func fetchRemoteConfig(from endpoint: URL) async throws -> RemoteConfiguration
}

class NIDNetworkServiceImpl: NetworkServiceProtocol {
    private let logger: LoggerProtocol
    private var afCustomSession: Alamofire.Session
    private let configuration = URLSessionConfiguration.af.default

    init(logger: LoggerProtocol) {
        self.logger = logger
        // Initialize the session
        self.afCustomSession = Alamofire.Session(configuration: configuration)
    }

    func retryableRequest(
        url: URL,
        neuroHTTPRequest: NeuroHTTPRequest,
        headers: HTTPHeaders,
        retryCount: Int = 0,
        completion: @escaping (AFDataResponse<Data>) -> Void
    ) {
        let maxRetryCount = 3

        configuration.timeoutIntervalForRequest = Double(NeuroID.shared.configService.configCache.requestTimeout)

        afCustomSession.request(
            url,
            method: .post,
            parameters: neuroHTTPRequest,
            encoder: JSONParameterEncoder.default,
            headers: headers
        ).validate().responseData { response in
            if let _ = response.error, response.response?.statusCode != 403, retryCount < maxRetryCount {
                self.logger.i("NeuroID network Retrying... attempt \(retryCount + 1)")
                self.retryableRequest(url: url, neuroHTTPRequest: neuroHTTPRequest, headers: headers, retryCount: retryCount + 1, completion: completion)
            } else {
                completion(response)
            }
        }
    }
    
    func fetchRemoteConfig(from endpoint: URL) async throws -> RemoteConfiguration {
        let (data, response) = try await URLSession.shared.data(from: endpoint)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let config: RemoteConfiguration = try JSONDecoder().decode(RemoteConfiguration.self, from: data)
        
        return config
    }
}
