//
//  DeviceMetadataTests.swift
//  NeuroID
//
//  Created by Collin Dunphy on 2/5/26.
//

import Testing
@testable import NeuroID

@Suite("Device Metadata Tests")
struct DeviceMetadataTests {
    
    @Test func deviceModelIdentifier() {
        // Can only target simulator devices for testing
        #expect(DeviceMetadata.getModelIdentifier() == "simulator")
    }
}
