//
//  AdvancedDeviceServiceTests.swift
//  NeuroID
//
//  Created by Collin Dunphy on 11/6/25.
//

import XCTest
@testable import NeuroID
import FingerprintPro

class AdvancedDeviceServiceTests: XCTestCase {
        
    // MARK: - AdvancedDeviceService endpoint selection

    // When `useAdvancedDeviceProxy` is disabled it should select the standard endpoint domain only
    func testEndpointUsesStandardWhenProxyDisabled() {
        XCTAssertEqual(
            AdvancedDeviceService.endpoint(useProxy: false),
            .custom(domain: AdvancedDeviceService.Endpoints.standard.url),
            "Standard endpoint configuration should match"
        )
    }

    // When `useAdvancedDeviceProxy` is enabled it should select the proxy domain with the standard domain as a fallback
    func testEndpointUsesProxyWhenEnabled() {
        XCTAssertEqual(
            AdvancedDeviceService.endpoint(useProxy: true),
            .custom(
                domain: AdvancedDeviceService.Endpoints.proxy.url,
                fallback: [AdvancedDeviceService.Endpoints.standard.url]
            ),
            "Proxy endpoint configuration should match"
        )
    }
}
