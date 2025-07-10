//
//  NIDLogTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//
@testable import NeuroID
import XCTest

class NIDLogTests: XCTestCase {
    func test_enableLogging_true() {
        NeuroID.enableLogging(true)

        assert(NeuroID.showLogs)
    }

    func test_enableLogging_false() {
        NeuroID.enableLogging(false)

        assert(!NeuroID.showLogs)
    }
}
