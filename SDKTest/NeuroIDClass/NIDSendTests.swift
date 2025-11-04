//
//  NIDSendTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//
@testable import NeuroID
import XCTest

class NIDSendTests: BaseTestClass {
    override func setUpWithError() throws {
        NeuroID.shared.networkService = MockNetworkService()
        NeuroID.shared.configService = MockConfigService()
        let configuration = NeuroID.Configuration(clientKey: clientKey, isAdvancedDevice: false)
        _ = NeuroID.configure(configuration)
        NeuroID.shared.sendCollectionEventsJob.cancel()
        NeuroID._isTesting = true

        clearOutDataStore()
    }

    override func tearDown() {
        _ = NeuroID.stop()
        // Clear out the DataStore Events after each test
        clearOutDataStore()
        NeuroID._isTesting = false
    }

    func test_sendCollectionEventsJob() {
        var valueChanged = 0
        let expectations1 = XCTestExpectation(description: "Wait for 3 seconds pt 1")
        let expectations2 = XCTestExpectation(description: "Wait for 3 seconds pt 2")

        NeuroID.shared.sendCollectionEventsJob.cancel()

        NeuroID.shared.sendCollectionEventsJob = RepeatingTask(
            interval: 0.5,
            task: {
                valueChanged += 1
                if valueChanged == 1 {
                    expectations1.fulfill()
                } else if valueChanged == 2 {
                    expectations2.fulfill()
                } else {
                    print("ERROR - Unknown Expectation")
                    XCTAssertThrowsError("Unknown Expectation - sendCollectionEventsJob")
                }
            }
        )

        NeuroID.shared.sendCollectionEventsJob.start()

        wait(for: [expectations1], timeout: 7)
        assert(valueChanged == 1)

        wait(for: [expectations2], timeout: 7)
        assert(valueChanged == 2)

        NeuroID.shared.sendCollectionEventsJob.cancel()
    }
}
