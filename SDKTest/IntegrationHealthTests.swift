//
//  IntegrationHealthTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 4/24/23.
//

@testable import NeuroID
import XCTest

class IntegrationHealthTests: XCTestCase {
    func test_generateTargetEvents() {
        let events = generateEvents()
        assert(events.count == 14)

        writeNIDEventsToJSON(Contstants.integrationHealthFile.rawValue, items: events)
    }
}
