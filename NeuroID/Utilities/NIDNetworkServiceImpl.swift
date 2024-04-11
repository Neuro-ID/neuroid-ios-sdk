//
//  NIDNetworkingService.swift
//  NeuroID
//
//  Created by Clayton Selby on 2/15/24.
//

import Foundation
import Alamofire

class NIDNetworkServiceImpl: NIDNetworkServiceProtocol {

    private var afCustomSession: Alamofire.Session
    private let configuration = URLSessionConfiguration.af.default
    
    init() {
    
        // Initialize the session
        self.afCustomSession = Alamofire.Session(configuration: configuration)
    }

    func retryableRequest(url: URL, neuroHTTPRequest: NeuroHTTPRequest, headers: HTTPHeaders, retryCount: Int = 0, completion: @escaping (AFDataResponse<Data>) -> Void) {
        let maxRetryCount = 3
        
        configuration.timeoutIntervalForRequest = Double(NIDConfigService.nidConfigCache.requestTimeout)
        
        afCustomSession.request(
            url,
            method: .post,
            parameters: neuroHTTPRequest,
            encoder: JSONParameterEncoder.default,
            headers: headers
        ).validate().responseData { response in
            if let error = response.error, response.response?.statusCode != 403, retryCount < maxRetryCount {
                NIDLog.i("NeuroID network Retrying... attempt \(retryCount + 1)")
                self.retryableRequest(url: url, neuroHTTPRequest: neuroHTTPRequest, headers: headers, retryCount: retryCount + 1, completion: completion)
            } else {
                completion(response)
            }
        }
    }

}
