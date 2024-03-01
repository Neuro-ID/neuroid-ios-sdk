//
//  NIDNetworkServiceTestImpl.swift
//  SDKTest
//
//  Created by Clayton Selby on 2/15/24.
//

import Foundation
import Alamofire
@testable import NeuroID

class NIDNetworkServiceTestImpl: NIDNetworkServiceProtocol {
    var mockResponse: Data?
    var mockError: Error?
    

    func retryableRequest(url: URL, neuroHTTPRequest: NeuroHTTPRequest, headers: HTTPHeaders, retryCount: Int, completion: @escaping (AFDataResponse<Data>) -> Void) {
        // Set collection URL to dev
        NeuroID.collectionURL = "https://receiver.neuroid-dev.com/c"
        
        print("NIDNetworkServiceTestImpl Mocked Request \(neuroHTTPRequest)")
    }
    
    func createMockAlamofireResponse(successful: Bool, responseData: Data?, statusCode: Int) -> AFDataResponse<Data> {
        let url = URL(string: "https://mock-nid.com")!
        let request = URLRequest(url: url)

        let response = HTTPURLResponse(url: url, statusCode: successful ? 200 : 500, httpVersion: nil, headerFields: nil)

        var result: Result<Data, AFError>
            if successful {
                result = .success(responseData ?? Data())
            } else {
                let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: statusCode))
                result = .failure(error)
            }

        let mockResponse = AFDataResponse<Data>(
            request: request,
            response: response,
            data: responseData,
            metrics: nil,
            serializationDuration: 0,
            result: result
        )

        return mockResponse
    }
}
