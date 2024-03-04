//
//  NIDNetworkingService.swift
//  NeuroID
//
//  Created by Clayton Selby on 2/15/24.
//

import Foundation
import Alamofire

class NIDNetworkServiceImpl: NIDNetworkServiceProtocol {

    func retryableRequest(url: URL, neuroHTTPRequest: NeuroHTTPRequest, headers: HTTPHeaders, retryCount: Int, completion: @escaping (AFDataResponse<Data>) -> Void) {
        AF.request(
            url,
            method: .post,
            parameters: neuroHTTPRequest,
            encoder: JSONParameterEncoder.default,
            headers: headers
        ).validate().responseData { response in
            if response.error != nil, retryCount > 0, response.response?.statusCode != 403 {
                NIDLog.i("NeuroID network Retrying...")
                self.retryableRequest(url: url, neuroHTTPRequest: neuroHTTPRequest, headers: headers, retryCount: retryCount - 1, completion: completion)
            } else { completion(response) }
        }
    }
}
