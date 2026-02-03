//
//  NIDLogTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//
@testable import NeuroID
import Testing

@Suite("NID Log Tests")
struct NIDLogTests {
    
    @Test func enableLogging() {
        NeuroID.enableLogging(true)
        assert(NeuroID.shared.showLogs)
    }

    @Test
    func disableLogging() {
        NeuroID.enableLogging(false)
        assert(!NeuroID.shared.showLogs)
    }
}
