//
//  Configuration.swift
//  NeuroID
//
//  Created by Collin Dunphy on 11/4/25.
//

extension NeuroID {
    public struct Configuration {
        public var clientKey: String
        public var region: Region
        public var isAdvancedDevice: Bool
        public var advancedDeviceKey: String?
        public var useAdvancedDeviceProxy: Bool

        public init(
            clientKey: String,
            region: Region? = nil,
            isAdvancedDevice: Bool? = nil,
            advancedDeviceKey: String? = nil,
            useAdvancedDeviceProxy: Bool? = nil
        ) {
            self.clientKey = clientKey
            self.region = region ?? .usWest
            self.isAdvancedDevice = isAdvancedDevice ?? false
            self.advancedDeviceKey = advancedDeviceKey
            self.useAdvancedDeviceProxy = useAdvancedDeviceProxy ?? true
        }

        var environment: String {
            return clientKey.contains("_live_") ? Constants.environmentLive.rawValue : Constants.environmentTest.rawValue
        }
    }
}
