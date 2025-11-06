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
    
    override func tearDown() {
        // Reset state to prevent test pollution
        NeuroID.shared.useFingerprintProxy = false
        NeuroID.shared.deviceSignalService = AdvancedDeviceService()
        super.tearDown()
    }
    
    // MARK: - Configuration Propagation Tests
    
    // Test that Configuration properly sets the proxy flag
    func testConfigureWithFingerprintProxyEnabled() {
        config.useFingerprintProxy = true
        let _ = NeuroID.configure(config)
        
        XCTAssertTrue(NeuroID.shared.useFingerprintProxy, "Proxy flag should be enabled after configuration")
    }
    
    // Test explicit proxy disabled
    func testConfigureWithFingerprintProxyDisabled() {
        config.useFingerprintProxy = false
        let _ = NeuroID.configure(config)
        
        XCTAssertFalse(NeuroID.shared.useFingerprintProxy, "Proxy flag should be disabled when explicitly set to false")
    }

    // Test default value when not specified
    func testConfigureFingerprintProxyDefaultsToFalse() {
        let _ = NeuroID.configure(config)
        
        XCTAssertFalse(NeuroID.shared.useFingerprintProxy, "Proxy flag should default to false when not specified")
    }
    
    
    // Test that the value changes on reconfigure
    func testReconfigureChangesProxySetting() {
        // First configure with proxy enabled
        config.useFingerprintProxy = true
        let _ = NeuroID.configure(config)
        
        XCTAssertTrue(NeuroID.shared.useFingerprintProxy, "Initial configuration should enable proxy")
        
        // Reconfigure with proxy disabled
        config.useFingerprintProxy = false
        let _ = NeuroID.configure(config)
        
        XCTAssertFalse(NeuroID.shared.useFingerprintProxy, "Reconfiguration should disable proxy")
    }
}
