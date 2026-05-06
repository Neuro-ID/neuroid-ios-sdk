//
//  ConfigurationTests.swift
//  NeuroID
//
//  Created by Collin Dunphy on 11/4/25.
//

import Testing

@testable import NeuroID

@Suite(.serialized)
struct ConfigurationTests {

    var neuroID: NeuroIDCore
    var config: NeuroID.Configuration

    init() {
        neuroID = NeuroIDCore()
        config = NeuroID.Configuration(
            clientKey: "key_live_123456",
            isAdvancedDevice: true
        )
    }

    // MARK: - `useAdvancedDeviceProxy` Tests

    // Test that Configuration properly sets the proxy flag
    @Test("Proxy flag should be enabled after configuration")
    mutating func testConfigureWithProxyEnabled() {
        config.useAdvancedDeviceProxy = true
        let _ = neuroID.configure(config)
        #expect(neuroID.useAdvancedDeviceProxy)
    }

    // Test explicit proxy disabled
    @Test("Proxy flag should be disabled when explicitly set to false")
    mutating func testConfigureWithProxyDisabled() {
        config.useAdvancedDeviceProxy = false
        let _ = neuroID.configure(config)
        #expect(!neuroID.useAdvancedDeviceProxy)
    }

    // Test default value when not specified
    @Test("Proxy flag should default to true when not specified")
    func testConfigureProxyDefaults() {
        let _ = neuroID.configure(config)
        #expect(neuroID.useAdvancedDeviceProxy)
    }

    // MARK: Environment Tests

    @Test
    func testDefaultEnvironment() {
        #expect(neuroID.getEnvironment() == "TEST")
    }

    @Test
    func testLiveEnvironment() {
        let _ = neuroID.configure(config)
        #expect(neuroID.getEnvironment() == "LIVE")
    }

    @Test
    mutating func testTestEnvironment() {
        config.clientKey = "key_test_123456"
        let _ = neuroID.configure(config)
        #expect(neuroID.getEnvironment() == "TEST")
    }
}
