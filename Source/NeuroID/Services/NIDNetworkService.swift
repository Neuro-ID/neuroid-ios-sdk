//
//  NIDNetworkingService.swift
//  NeuroID
//
//  Created by Clayton Selby on 2/15/24.
//

import Alamofire
import Foundation

protocol NIDNetworkServiceProtocol {
    func retryableRequest(url: URL, neuroHTTPRequest: NeuroHTTPRequest, headers: HTTPHeaders, retryCount: Int, completion: @escaping (AFDataResponse<Data>) -> Void)

    func getRequest<T: Decodable>(url: URL, responseDecodableType: T.Type, completion: @escaping (DataResponse<T, AFError>) -> Void)
}


class NIDNetworkServiceImpl: NIDNetworkServiceProtocol {
    private var afCustomSession: Alamofire.Session
    private let configuration = URLSessionConfiguration.af.default

    init() {
        // Initialize the session
        self.afCustomSession = Alamofire.Session(configuration: configuration)
    }

    func retryableRequest(url: URL, neuroHTTPRequest: NeuroHTTPRequest, headers: HTTPHeaders, retryCount: Int = 0, completion: @escaping (AFDataResponse<Data>) -> Void) {
        let maxRetryCount = 3

        configuration.timeoutIntervalForRequest = Double(NeuroID.configService.configCache.requestTimeout)

        afCustomSession.request(
            url,
            method: .post,
            parameters: neuroHTTPRequest,
            encoder: JSONParameterEncoder.default,
            headers: headers
        ).validate().responseData { response in
            if let _ = response.error, response.response?.statusCode != 403, retryCount < maxRetryCount {
                NIDLog.i("NeuroID network Retrying... attempt \(retryCount + 1)")
                self.retryableRequest(url: url, neuroHTTPRequest: neuroHTTPRequest, headers: headers, retryCount: retryCount + 1, completion: completion)
            } else {
                completion(response)
            }
        }
    }

    func getRequest<T: Decodable>(
        url: URL,
        responseDecodableType: T.Type,
        completion: @escaping (DataResponse<T, AFError>) -> Void
    ) {
        afCustomSession
            .request(
                url,
                method: .get
            )
            .validate()
            .responseDecodable(of: responseDecodableType.self) { response in
                completion(response)
            }
    }
}
