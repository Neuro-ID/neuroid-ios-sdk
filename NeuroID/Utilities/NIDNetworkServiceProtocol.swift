//
//  NIDNetworkServiceProtocol.swift
//  NeuroID
//
//  Created by Clayton Selby on 2/15/24.
//

import Foundation
import Alamofire

protocol NIDNetworkServiceProtocol {
    func retryableRequest(url: URL, neuroHTTPRequest: NeuroHTTPRequest, headers: HTTPHeaders, completion: @escaping (AFDataResponse<Data>) -> Void)
}
