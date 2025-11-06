//
//  AdvancedDeviceServiceTests.swift
//  NeuroID
//
//  Created by Collin Dunphy on 11/6/25.
//

import XCTest
@testable import NeuroID

class AdvancedDeviceServiceTests: XCTestCase {
    
    // MARK: - FingerprintEndpoint
    func testFingerprintEndpointStandardUrl() {
        let standardURL = AdvancedDeviceService.FingerprintEndpoint.standard.url
        XCTAssertEqual(standardURL, "https://advanced.neuro-id.com", "Standard endpoint should use correct URL")
    }
    
    func testFingerprintEndpointProxyUrl() {
        let proxyURL = AdvancedDeviceService.FingerprintEndpoint.proxy.url
        XCTAssertEqual(proxyURL, "https://dn.neuroid.cloud/iynlfqcb0t", "Proxy endpoint should use correct URL")
    }
}
