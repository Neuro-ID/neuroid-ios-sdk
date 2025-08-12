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

    var shouldMockFalse = false

    var mockedRetryableRequestSuccess = 0
    var mockedRetryableRequestFailure = 0

    func resetMockCounts() {
        mockedRetryableRequestSuccess = 0
        mockedRetryableRequestFailure = 0
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
        shouldMockFalse = true
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

        if shouldMockFalse {
            mockedRetryableRequestFailure += 1
        } else {
            mockedRetryableRequestSuccess += 1
        }

        let mockResponse = createMockAlamofireResponse(
            successful: !shouldMockFalse,
            responseData: nil,
            statusCode: 200
        )

        completion(mockResponse)
    }

    func getRequest<T: Decodable>(
        url: URL,
        responseDecodableType: T.Type,
        completion: @escaping (DataResponse<T, AFError>) -> Void
    ) {
        if shouldMockFalse {
            let request = URLRequest(url: URL(string: "https://mock-nid.com")!)
            let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)

            var result: Result<T, AFError>
            let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 500))
            result = .failure(error)

            let finalRes: DataResponse<T, AFError> = .init(
                request: request,
                response: response,
                data: mockResponse,
                metrics: nil,
                serializationDuration: 0,
                result: result
            )

            completion(finalRes)

            shouldMockFalse = false
            return
        } else {
            let request = URLRequest(url: URL(string: "https://mock-nid.com")!)
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)

            var result: Result<T, AFError>
            result = .success(mockResponseResult as! T)

            let finalRes: DataResponse<T, AFError> = .init(
                request: request,
                response: response,
                data: mockResponse,
                metrics: nil,
                serializationDuration: 0,
                result: result
            )

            completion(finalRes)

            shouldMockFalse = false
            return
        }

        print("MockNetworkService Mocked GET Request \(url)")
    }
}
