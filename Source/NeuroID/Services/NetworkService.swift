//
//  NetworkService.swift
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

class NetworkService: NetworkServiceProtocol {
    private var afCustomSession: Alamofire.Session
    private let afConfiguration = URLSessionConfiguration.af.default
    private let session: URLSession

    init() {
        // Initialize the session
        self.afCustomSession = Alamofire.Session(configuration: afConfiguration)
        
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration)
        session.sessionDescription = "NeuroID"
    }
    
    internal init(session: URLSession) {
        self.afCustomSession = Alamofire.Session(configuration: afConfiguration)

        self.session = session
    }

    func retryableRequest(
        url: URL,
        neuroHTTPRequest: NeuroHTTPRequest,
        headers: HTTPHeaders,
        retryCount: Int = 0,
        completion: @escaping (AFDataResponse<Data>) -> Void
    ) {
        let maxRetryCount = 3

        afConfiguration.timeoutIntervalForRequest = Double(NeuroID.shared.configService.configCache.requestTimeout)

        afCustomSession.request(
            url,
            method: .post,
            parameters: neuroHTTPRequest,
            encoder: JSONParameterEncoder.default,
            headers: headers
        ).validate().responseData { response in
            if let _ = response.error, response.response?.statusCode != 403, retryCount < maxRetryCount {
                NIDLog.info("NeuroID network Retrying... attempt \(retryCount + 1)")
                self.retryableRequest(url: url, neuroHTTPRequest: neuroHTTPRequest, headers: headers, retryCount: retryCount + 1, completion: completion)
            } else {
                completion(response)
            }
        }
    }
    
    public func fetchRemoteConfig(from endpoint: URL) async throws -> RemoteConfiguration {
        let (data, response) = try await session.data(from: endpoint)
        
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(RemoteConfiguration.self, from: data)
    }
}
