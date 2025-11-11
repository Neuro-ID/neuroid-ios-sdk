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
        let configuration = Configuration(clientKey: clientKey, isAdvancedDevice: false)
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
        let exp = expectation(description: "D")
        exp.expectedFulfillmentCount = 2
        exp.assertForOverFulfill = true
        
        let counterQ = DispatchQueue(label: "nid.tests.counter")
        var valueChanged = 0
        
        NeuroID.shared.sendCollectionEventsJob.cancel()

        NeuroID.shared.sendCollectionEventsJob = RepeatingTask(
            interval: 0.5,
            task: {
                let newValue = counterQ.sync {
                    valueChanged += 1
                    return valueChanged
                }
                exp.fulfill()
                
                if newValue == 2 {
                    NeuroID.shared.sendCollectionEventsJob.cancel()
                }
            }
        )

        NeuroID.shared.sendCollectionEventsJob.start()

        wait(for: [exp], timeout: 7)

        let finalCount = counterQ.sync { valueChanged }
        XCTAssertGreaterThanOrEqual(finalCount, 2)
    }
}
