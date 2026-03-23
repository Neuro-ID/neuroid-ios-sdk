//
//  NIDEnvTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//

@testable import NeuroID
import XCTest

class NIDEnvTests: XCTestCase {
    func test_getEnvironment() {
        NeuroIDCore.shared.environment = Constants.environmentTest.rawValue
        assert(NeuroID.getEnvironment() == "TEST")
    }
}
