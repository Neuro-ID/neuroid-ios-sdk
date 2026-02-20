//
//  IntegrationHealthTests.swift
//  NeuroID
//

import Testing

@testable import NeuroID

@Suite("Integration Health Tests")
struct IntegrationHealthTests {

    @Test
    func testPrintIntegrationHealthInstruction() {
        NeuroID.printIntegrationHealthInstruction()
    }

    @Test
    func testSetVerifyIntegrationHealth() {
        NeuroID.setVerifyIntegrationHealth(true)
    }
}
