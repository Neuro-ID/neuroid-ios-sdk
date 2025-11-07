//
//  ConfigurationTests.swift
//  NeuroID
//
//  Created by Collin Dunphy on 11/4/25.
//

import XCTest
@testable import NeuroID

class ConfigurationTests: XCTestCase {
    
    var config = NeuroID.Configuration(
        clientKey: "test_key",
        isAdvancedDevice: true
    )
    
    override func setUp() {
        super.setUp()
        NeuroID._isTesting = true
    }
    
    // MARK: - `useAdvancedDeviceProxy` Tests
    
    // Test that Configuration properly sets the proxy flag
    func testConfigureWithFingerprintProxyEnabled() {
        config.useAdvancedDeviceProxy = true
        let _ = NeuroID.configure(config)
        
        XCTAssertTrue(NeuroID.shared.useAdvancedDeviceProxy, "Proxy flag should be enabled after configuration")
    }
    
    // Test explicit proxy disabled
    func testConfigureWithFingerprintProxyDisabled() {
        config.useAdvancedDeviceProxy = false
        let _ = NeuroID.configure(config)
        
        XCTAssertFalse(NeuroID.shared.useAdvancedDeviceProxy, "Proxy flag should be disabled when explicitly set to false")
    }

    // Test default value when not specified
    func testConfigureFingerprintProxyDefaultsToFalse() {
        let _ = NeuroID.configure(config)
        
        XCTAssertFalse(NeuroID.shared.useAdvancedDeviceProxy, "Proxy flag should default to false when not specified")
    }
    
    
    // Test that the value changes on reconfigure
    func testReconfigureChangesProxySetting() {
        // First configure with proxy enabled
        config.useAdvancedDeviceProxy = true
        let _ = NeuroID.configure(config)
        
        XCTAssertTrue(NeuroID.shared.useAdvancedDeviceProxy, "Initial configuration should enable proxy")
        
        // Reconfigure with proxy disabled
        config.useAdvancedDeviceProxy = false
        let _ = NeuroID.configure(config)
        
        XCTAssertFalse(NeuroID.shared.useAdvancedDeviceProxy, "Reconfiguration should disable proxy")
    }

}
