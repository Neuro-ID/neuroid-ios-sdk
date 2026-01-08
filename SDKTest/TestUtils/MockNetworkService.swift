//
//  MockNetworkService.swift
//  SDKTest
//
//  Created by Clayton Selby on 2/15/24.
//

import Alamofire
import Foundation
@testable import NeuroID

class MockNetworkService: NetworkServiceProtocol {
    var mockResponse: Data?
    var mockResponseResult: Any?
    var mockError: Error?

    var mockRequestShouldFail = false

    var mockedRetryableRequestSuccess = 0
    var mockedRetryableRequestFailure = 0

    var fetchRemoteConfigSuccessCount = 0
    var fetchRemoteConfigFailureCount = 0

    func resetMockCounts() {
        mockedRetryableRequestSuccess = 0
        mockedRetryableRequestFailure = 0
        fetchRemoteConfigSuccessCount = 0
        fetchRemoteConfigFailureCount = 0
    }

    // Mock Class Utils
    func createMockAlamofireResponse(
        successful: Bool,
        responseData: Data?,
        statusCode: Int
    ) -> AFDataResponse<Data> {
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

    func mockFailedResponse() {
        mockRequestShouldFail = true
    }

    // Protocol Implementations
   func retryableRequest(
       url: URL,
       neuroHTTPRequest: NeuroHTTPRequest,
       headers: HTTPHeaders,
       retryCount: Int,
       completion: @escaping (AFDataResponse<Data>) -> Void
   ) {
       print("MockNetworkService Mocked retryableRequest \(neuroHTTPRequest)")

       if mockRequestShouldFail {
           mockedRetryableRequestFailure += 1
       } else {
           mockedRetryableRequestSuccess += 1
       }

       let mockResponse = createMockAlamofireResponse(
           successful: !mockRequestShouldFail,
           responseData: nil,
           statusCode: 200
       )

       completion(mockResponse)
   }

    func fetchRemoteConfig(from endpoint: URL) async throws -> RemoteConfiguration {
        if mockRequestShouldFail {
            fetchRemoteConfigFailureCount += 1
            throw URLError(.unknown)
        } else {
            fetchRemoteConfigSuccessCount += 1
            return mockResponseResult as! RemoteConfiguration
        }
    }
}
