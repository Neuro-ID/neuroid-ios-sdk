//
//  NetworkMonitoringServiceTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 1/31/24.
//

@testable import NeuroID
import XCTest

class NetworkMonitoringServiceTests: XCTestCase {
    var sut: NetworkMonitoringService!

    override func setUp() {
        super.setUp()
        sut = NetworkMonitoringService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testStartMonitoring() {
        sut.startMonitoring()

        // Wait for a few seconds to allow the network monitor to update
        let expectation = self.expectation(description: "Wait for network monitor to update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)

        XCTAssertTrue(sut.isConnected)
        XCTAssertNotEqual(sut.connectionType, .unknown)
    }
}
