//
//  ConfigurationTests.swift
//  NeuroID
//
//  Created by Collin Dunphy on 11/4/25.
//

import Testing
@testable import NeuroID

@Suite("Configuration")
struct ConfigurationTests {
    
    // MARK: - `useAdvancedDeviceProxy` Tests
    
    @Test(
        "Configuration sets useAdvancedDeviceProxy correctly",
        arguments: [true, false, nil]
    )
    func configureWithProxyEnabled(useProxy: Bool?) {
        var config = NeuroID.Configuration(
            clientKey: "test_key",
            isAdvancedDevice: true
        )

        if let useProxy = useProxy {
            config.useAdvancedDeviceProxy = useProxy
        }

        let neuroID = NeuroID()
        _ = neuroID.configure(config)

        #expect(neuroID.useAdvancedDeviceProxy == useProxy ?? false)
    }
    
    @Test("Proxy setting changes on reconfiguration")
    func reconfigureChangesProxySetting() {
        let neuroID = NeuroID()
        var config = NeuroID.Configuration(
            clientKey: "test_key",
            isAdvancedDevice: true
        )
        
        // When: First configure with proxy enabled
        config.useAdvancedDeviceProxy = true
        _ = neuroID.configure(config)
        #expect(neuroID.useAdvancedDeviceProxy)
        
        // When: Reconfigure with proxy disabled
        config.useAdvancedDeviceProxy = false
        _ = neuroID.configure(config)
        #expect(!neuroID.useAdvancedDeviceProxy)
    }
}
