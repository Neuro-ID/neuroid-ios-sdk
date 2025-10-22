//
//  AdvancedDeviceServiceTests.swift
//  SDKTest
//
//  Created by GitHub Copilot on 10/22/25.
//

@testable import NeuroID
import XCTest

class AdvancedDeviceServiceTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - Helper Functions
    struct EndpointDistribution {
        let primaryPercentage: Double
        let canaryPercentage: Double
        let defaultPercentage: Double
        let primaryCount: Int
        let canaryCount: Int
        let defaultCount: Int
        let totalIterations: Int
    }
    
    func measureEndpointDistribution(primaryRate: Int, canaryRate: Int, iterations: Int = 10000) -> EndpointDistribution {
        var primaryCount = 0
        var canaryCount = 0
        var defaultCount = 0
        
        for _ in 1...iterations {
            let result = AdvancedDeviceService.determineEndpoint(primaryRate: primaryRate, canaryRate: canaryRate)
            switch result {
            case .primaryProxy:
                primaryCount += 1
            case .canaryProxy:
                canaryCount += 1
            case .standard:
                defaultCount += 1
            }
        }
        
        let primaryPercentage = Double(primaryCount) / Double(iterations) * 100
        let canaryPercentage = Double(canaryCount) / Double(iterations) * 100
        let defaultPercentage = Double(defaultCount) / Double(iterations) * 100
        
        return EndpointDistribution(
            primaryPercentage: primaryPercentage,
            canaryPercentage: canaryPercentage,
            defaultPercentage: defaultPercentage,
            primaryCount: primaryCount,
            canaryCount: canaryCount,
            defaultCount: defaultCount,
            totalIterations: iterations
        )
    }
    
    func assertDistribution(_ distribution: EndpointDistribution, 
                          expectedPrimary: Double, 
                          expectedCanary: Double, 
                          expectedDefault: Double, 
                          tolerance: Double = 2.0,
                          file: StaticString = #file,
                          line: UInt = #line) {
        XCTAssertTrue(
            abs(distribution.primaryPercentage - expectedPrimary) < tolerance,
            "Primary should be ~\(expectedPrimary)%, got \(distribution.primaryPercentage)%"
        )
        XCTAssertTrue(
            abs(distribution.canaryPercentage - expectedCanary) < tolerance,
            "Canary should be ~\(expectedCanary)%, got \(distribution.canaryPercentage)%"
        )
        XCTAssertTrue(
            abs(distribution.defaultPercentage - expectedDefault) < tolerance,
            "Default should be ~\(expectedDefault)%, got \(distribution.defaultPercentage)%"
        )
    }
    
    // MARK: - determineEndpoint() Tests
    func test_determineEndpoint_bothRatesZero_returnsDefault() {
        let primaryRate = 0
        let canaryRate = 0
        let result = AdvancedDeviceService.determineEndpoint(primaryRate: primaryRate, canaryRate: canaryRate)
        XCTAssertEqual(result.url, "https://advanced.neuro-id.com", "Should return default endpoint when both rates are 0")
    }
    
    func test_determineEndpoint_primaryRate10_canaryRate10() {
        let distribution = measureEndpointDistribution(primaryRate: 10, canaryRate: 10)
        assertDistribution(distribution, expectedPrimary: 10.0, expectedCanary: 10.0, expectedDefault: 80.0)
    }
    
    func test_determineEndpoint_primaryRate90_canaryRate10() {
        let distribution = measureEndpointDistribution(primaryRate: 90, canaryRate: 10)
        assertDistribution(distribution, expectedPrimary: 90.0, expectedCanary: 10.0, expectedDefault: 0.0, tolerance: 1.0)
    }
    
    func test_determineEndpoint_primaryRate100_canaryRate10() {
        let distribution = measureEndpointDistribution(primaryRate: 100, canaryRate: 10, iterations: 1000)
        assertDistribution(distribution, expectedPrimary: 100.0, expectedCanary: 0.0, expectedDefault: 0.0, tolerance: 0.5)
    }
    
    // Deterministic case: exactly 100% primary (capped), 0% others
    func test_determineEndpoint_primaryRate250_canaryRate10() {
        let distribution = measureEndpointDistribution(primaryRate: 250, canaryRate: 10, iterations: 1000)
        assertDistribution(distribution, expectedPrimary: 100.0, expectedCanary: 0.0, expectedDefault: 0.0, tolerance: 0.5)
    }
    
    func test_determineEndpoint_primaryRate50_canaryRate50() {
        let distribution = measureEndpointDistribution(primaryRate: 50, canaryRate: 50)
        assertDistribution(distribution, expectedPrimary: 50.0, expectedCanary: 50.0, expectedDefault: 0.0, tolerance: 1.0)
    }
    
    // MARK: - Edge Cases
    func test_determineEndpoint_primaryRateOnly() {
        let distribution = measureEndpointDistribution(primaryRate: 30, canaryRate: 0)
        
        // Then - Canary should be exactly 0% (deterministic), others probabilistic
        assertDistribution(distribution, expectedPrimary: 30.0, expectedCanary: 0.0, expectedDefault: 70.0)
        XCTAssertEqual(distribution.canaryCount, 0, "Canary should be exactly 0 when rate is 0")
    }
    
    func test_determineEndpoint_canaryRateOnly() {
        let distribution = measureEndpointDistribution(primaryRate: 0, canaryRate: 40)
        
        // Then - Primary should be exactly 0% (deterministic), others probabilistic  
        assertDistribution(distribution, expectedPrimary: 0.0, expectedCanary: 40.0, expectedDefault: 60.0)
        XCTAssertEqual(distribution.primaryCount, 0, "Primary should be exactly 0 when rate is 0")
    }
    
    func test_determineEndpoint_negativeRates() {
        let result = AdvancedDeviceService.determineEndpoint(primaryRate: -10, canaryRate: -5)
        XCTAssertEqual(result.url, "https://advanced.neuro-id.com", "Negative rates should default to default endpoint")
    }
    
    func test_determineEndpoint_veryHighRates() {
        let distribution = measureEndpointDistribution(primaryRate: 200, canaryRate: 300, iterations: 1000)
        assertDistribution(distribution, expectedPrimary: 100.0, expectedCanary: 0.0, expectedDefault: 0.0, tolerance: 0.1)
    }
      
    func test_determineEndpoint_primaryRate80_canaryRate30() {
        let distribution = measureEndpointDistribution(primaryRate: 80, canaryRate: 30)
        assertDistribution(distribution, expectedPrimary: 80.0, expectedCanary: 20.0, expectedDefault: 0.0, tolerance: 1.0)
    }
    
    // MARK: - Config Integration Tests
    // Note: getRequestID integration with FingerprintPro SDK is difficult to test without extensive mocking.
    // These tests verify the config service integration that getRequestID relies on.
    
    func test_configService_readsProxySampleRates() {
        // Given
        let mockConfigService = MockConfigService()
        mockConfigService.mockConfigCache.proxyPrimaryEndpointSampleRate = 50
        mockConfigService.mockConfigCache.proxyRCEndpointSampleRate = 30
        
        let originalConfigService = NeuroID.shared.configService
        NeuroID.shared.configService = mockConfigService
        
        // When - Verify config values that getRequestID would read
        let primaryRate = NeuroID.shared.configService.configCache.proxyPrimaryEndpointSampleRate ?? 0
        let canaryRate = NeuroID.shared.configService.configCache.proxyRCEndpointSampleRate ?? 0
        
        // Then
        XCTAssertEqual(primaryRate, 50, "Should read primary rate from config")
        XCTAssertEqual(canaryRate, 30, "Should read canary rate from config")
        
        // Cleanup
        NeuroID.shared.configService = originalConfigService
    }
    
    func test_configService_handlesNilSampleRates() {
        // Given
        let mockConfigService = MockConfigService()
        mockConfigService.mockConfigCache.proxyPrimaryEndpointSampleRate = nil
        mockConfigService.mockConfigCache.proxyRCEndpointSampleRate = nil
        
        let originalConfigService = NeuroID.shared.configService
        NeuroID.shared.configService = mockConfigService
        
        // When - Verify nil coalescing behavior that getRequestID uses
        let primaryRate = NeuroID.shared.configService.configCache.proxyPrimaryEndpointSampleRate ?? 0
        let canaryRate = NeuroID.shared.configService.configCache.proxyRCEndpointSampleRate ?? 0
        
        // Then - Should default to 0 when nil
        XCTAssertEqual(primaryRate, 0, "Should default to 0 when primary rate is nil")
        XCTAssertEqual(canaryRate, 0, "Should default to 0 when canary rate is nil")
        
        // Cleanup
        NeuroID.shared.configService = originalConfigService
    }
    
    func test_endpointSelection_integratesWithConfigService_zeroRates() {
        // Given
        let mockConfigService = MockConfigService()
        mockConfigService.mockConfigCache.proxyPrimaryEndpointSampleRate = 0
        mockConfigService.mockConfigCache.proxyRCEndpointSampleRate = 0
        
        let originalConfigService = NeuroID.shared.configService
        NeuroID.shared.configService = mockConfigService
        
        // When - Simulate what getRequestID does: read from config and determine endpoint
        let primaryRate = NeuroID.shared.configService.configCache.proxyPrimaryEndpointSampleRate ?? 0
        let canaryRate = NeuroID.shared.configService.configCache.proxyRCEndpointSampleRate ?? 0
        let endpoint = AdvancedDeviceService.determineEndpoint(primaryRate: primaryRate, canaryRate: canaryRate)
        
        // Then - Should use default endpoint when both rates are 0
        XCTAssertEqual(endpoint.url, "https://advanced.neuro-id.com", "Should use default endpoint when both rates are 0")
        
        // Cleanup
        NeuroID.shared.configService = originalConfigService
    }
}
