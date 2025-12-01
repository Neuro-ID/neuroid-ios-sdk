//
//  AdvancedDeviceServiceTests.swift
//  NeuroID
//
//  Created by Collin Dunphy on 11/6/25.
//

import FingerprintPro
import Testing

@testable import NeuroID

@Suite("Advanced Device Service")
struct AdvancedDeviceServiceTests {

    @Test("Standard endpoint configuration should match")
    func testEndpointUsesStandardWhenProxyDisabled() {
        #expect(
            AdvancedDeviceService.endpoint(useProxy: false)
                == .custom(domain: AdvancedDeviceService.Endpoints.standard.url)
        )
    }

    // When `useAdvancedDeviceProxy` is enabled it should select the proxy domain with the standard domain as a fallback
    @Test("Proxy endpoint configuration should match")
    func testEndpointUsesProxyWhenEnabled() {
        #expect(
            AdvancedDeviceService.endpoint(useProxy: true)
                == .custom(
                    domain: AdvancedDeviceService.Endpoints.proxy.url,
                    fallback: [AdvancedDeviceService.Endpoints.standard.url]
                )
        )
    }
}
