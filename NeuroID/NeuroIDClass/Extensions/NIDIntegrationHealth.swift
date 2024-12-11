//
//  NIDIntegrationHealth.swift
//  NeuroID
//
//  Created by Kevin Sites on 12/10/24.
//

import Foundation

struct IntegrationHealthDeviceInfo: Codable {
    var name: String
    var systemName: String
    var systemVersion: String
    var isSimulator: Bool
    var Orientation: DeviceOrientation // different type

    var model: String
    var type: String
    var customDeviceType: String

    var nidSDKVersion: String
}

struct DeviceOrientation: Codable {
    var rawValue: Int
    var isFlat: Bool
    var isPortrait: Bool
    var isLandscape: Bool
    var isValid: Bool
}

protocol IntegrationHealthProtocol {
    // methods NID class relies on
    func startIntegrationHealthCheck() -> Void
    func captureIntegrationHealthEvent(_ event: NIDEvent) -> Void
    func saveIntegrationHealthEvents() -> Void
    
    // public methods User can access
    func printIntegrationHealthInstruction() -> Void
    func setVerifyIntegrationHealth(_ verify: Bool) -> Void
}

public extension NeuroID {
    static func printIntegrationHealthInstruction() {
        integrationHealthService?.printIntegrationHealthInstruction()
    }

    static func setVerifyIntegrationHealth(_ verify: Bool) {
        integrationHealthService?.setVerifyIntegrationHealth(verify)
    }
}
