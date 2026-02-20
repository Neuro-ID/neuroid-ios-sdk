//
//  NIDLogTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//

import Testing

@testable import NeuroID

@Suite("NID Log Tests")
struct NIDLogTests {

    @Test func enableLogging() {
        NeuroID.enableLogging(true)
        assert(NeuroIDCore.shared.showLogs)
    }

    @Test
    func disableLogging() {
        NeuroID.enableLogging(false)
        assert(!NeuroIDCore.shared.showLogs)
    }
}
