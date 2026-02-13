//
//  NetworkServiceTests.swift
//  NeuroID
//

import Foundation
import Testing

@testable import NeuroID

@Suite("Network Service Tests")
struct NetworkServiceTests {

    var networkService: NetworkService

    init() {
        let config = URLSessionConfiguration.default
        config.protocolClasses = [URLProtocolStub.self]

        let session = URLSession(configuration: config)
        session.sessionDescription = "NeuroID"

        networkService = NetworkService(session: session)
    }

    @Test
    func fetchRemoteConfigSuccess() async throws {
        let endpoint = URL(string: "https://api.example.com/remote-config")!
        let expected = RemoteConfiguration(sampleRate: 42)

        URLProtocolStub.handler = { request in
            #expect(request.url == endpoint)
            #expect(request.httpMethod == "GET")
            let data = try JSONEncoder().encode(expected)

            let response = HTTPURLResponse(
                url: endpoint,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!

            return (response, data)
        }

        let result = try await networkService.fetchRemoteConfig(from: endpoint)

        #expect(result == expected)
    }

    @Test(arguments: [401, 404, 500])
    func fetchRemoteConfigFailStatusCode(_ statusCode: Int) async throws {
        let endpoint = URL(string: "https://api.example.com/remote-config")!
        let expected = RemoteConfiguration(sampleRate: 42)

        URLProtocolStub.handler = { request in
            let data = try JSONEncoder().encode(expected)

            let response = HTTPURLResponse(
                url: endpoint,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!

            return (response, data)
        }

        await #expect(throws: URLError(.badServerResponse)) {
            _ = try await networkService.fetchRemoteConfig(from: endpoint)
        }
    }

    @Test(arguments: [Data(), Data(#"{"notTheRightKey": "hello"}"#.utf8)])
    func fetchRemoteConfigFailDecode(_ data: Data) async throws {
        let endpoint = URL(string: "https://api.example.com/remote-config")!

        URLProtocolStub.handler = { request in
            let response = HTTPURLResponse(
                url: endpoint,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!

            return (response, data)
        }

        await #expect(throws: DecodingError.self) {
            _ = try await networkService.fetchRemoteConfig(from: endpoint)
        }
    }
}

final class URLProtocolStub: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
