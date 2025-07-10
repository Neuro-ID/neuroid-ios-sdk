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
        NeuroID.environment = Constants.environmentTest.rawValue
        assert(NeuroID.getEnvironment() == "TEST")
    }

    func test_setEnvironmentProduction_true() {
        NeuroID.environment = ""
        NeuroID.setEnvironmentProduction(true)

        // Should do nothing because deprecated
        assert(NeuroID.getEnvironment() == "")
    }

    func test_setEnvironmentProduction_false() {
        NeuroID.environment = ""
        NeuroID.setEnvironmentProduction(false)

        // Should do nothing because deprecated
        assert(NeuroID.getEnvironment() == "")
    }
}
