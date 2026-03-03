//
//  Configuration.swift
//  NeuroID
//
//  Created by Collin Dunphy on 11/4/25.
//

extension NeuroID {
    public struct Configuration {
        public var clientKey: String
        public var isAdvancedDevice: Bool
        public var advancedDeviceKey: String?
        public var useAdvancedDeviceProxy: Bool

        public init(
            clientKey: String,
            isAdvancedDevice: Bool? = nil,
            advancedDeviceKey: String? = nil,
            useAdvancedDeviceProxy: Bool? = nil
        ) {
            self.clientKey = clientKey
            self.isAdvancedDevice = isAdvancedDevice ?? false
            self.advancedDeviceKey = advancedDeviceKey
            self.useAdvancedDeviceProxy = useAdvancedDeviceProxy ?? true
        }
    }
}
