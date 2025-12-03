//
//  DeviceMetadataTests.swift
//  SDKTest
//
//  Created by Collin Dunphy on 12/3/25.
//

import Testing
@testable import NeuroID

@Suite("Device Metadata Tests")
struct DeviceMetadataTests {
    
    @Test func deviceModelIdentifier() {
        #if targetEnvironment(simulator)
            // This is the arm macbook simulator
            #expect(NIDMetadata.getDeviceModelIdentifier() == "simulator")
        #else
            withKnownIssue("Untested on non-simulator platforms") {
                #expect(NIDMetadata.getDeviceModelIdentifier().contains("iPhone"))
            }
        #endif
    }
}
