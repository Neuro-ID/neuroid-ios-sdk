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

    func retryableRequest(url: URL, neuroHTTPRequest: NeuroHTTPRequest, headers: HTTPHeaders, completion: @escaping (AFDataResponse<Data>) -> Void) {
        
        configuration.timeoutIntervalForRequest = Double(NIDConfigService.nidConfigCache.requestTimeout)
        
        afCustomSession.request(
            url,
            method: .post,
            parameters: neuroHTTPRequest,
            encoder: JSONParameterEncoder.default,
            headers: headers
        ).validate().responseData { response in
            if response.error != nil, response.response?.statusCode != 403 {
                NIDLog.i("NeuroID network Retrying...")
                self.retryableRequest(url: url, neuroHTTPRequest: neuroHTTPRequest, headers: headers, completion: completion)
            } else { completion(response) }
        }
    }
}
