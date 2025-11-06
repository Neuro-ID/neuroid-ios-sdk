//
//  ConfigurationTests.swift
//  NeuroID
//
//  Created by Collin Dunphy on 11/4/25.
//

import XCTest
@testable import NeuroID

class ConfigureTests: XCTestCase {
    
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
    func test_configure_with_fingerprint_proxy_enabled() {
        config.useFingerprintProxy = true
        let _ = NeuroID.configure(config)
        
        XCTAssertTrue(NeuroID.shared.useFingerprintProxy, "Proxy flag should be enabled after configuration")
    }
    
    // Test explicit proxy disabled
    func test_configure_with_fingerprint_proxy_disabled() {
        config.useFingerprintProxy = false
        let _ = NeuroID.configure(config)
        
        XCTAssertFalse(NeuroID.shared.useFingerprintProxy, "Proxy flag should be disabled when explicitly set to false")
    }

    // Test default value when not specified
    func test_configure_fingerprint_proxy_defaults_to_false() {
        let _ = NeuroID.configure(config)
        
        XCTAssertFalse(NeuroID.shared.useFingerprintProxy, "Proxy flag should default to false when not specified")
    }
    
    
    // Test that the value changes on reconfigure
    func test_reconfigure_changes_proxy_setting() {
        // First configure with proxy enabled
        config.useFingerprintProxy = true
        let _ = NeuroID.configure(config)
        
        XCTAssertTrue(NeuroID.shared.useFingerprintProxy, "Initial configuration should enable proxy")
        
        // Reconfigure with proxy disabled
        config.useFingerprintProxy = false
        let _ = NeuroID.configure(config)
        
        XCTAssertFalse(NeuroID.shared.useFingerprintProxy, "Reconfiguration should disable proxy")
    }
    
    // MARK: - FingerprintEndpoint
    func test_fingerprint_endpoint_standard_url() {
        let standardURL = AdvancedDeviceService.FingerprintEndpoint.standard.url
        XCTAssertEqual(standardURL, "https://advanced.neuro-id.com", "Standard endpoint should use correct URL")
    }
    
    func test_fingerprint_endpoint_proxy_url() {
        let proxyURL = AdvancedDeviceService.FingerprintEndpoint.proxy.url
        XCTAssertEqual(proxyURL, "https://dn.neuroid.cloud/iynlfqcb0t", "Proxy endpoint should use correct URL")
    }
}
