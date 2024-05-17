//
//  NIDNetworkServiceProtocol.swift
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
