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

    func test_setEnvironmentProduction_true() {
        NeuroIDCore.shared.environment = ""
        NeuroID.setEnvironmentProduction(true)

        // Should do nothing because deprecated
        assert(NeuroID.getEnvironment() == "")
    }

    func test_setEnvironmentProduction_false() {
        NeuroIDCore.shared.environment = ""
        NeuroID.setEnvironmentProduction(false)

        // Should do nothing because deprecated
        assert(NeuroID.getEnvironment() == "")
    }
}
