//
//  Configuration.swift
//  NeuroID
//
//  Created by Collin Dunphy on 11/4/25.
//

extension NeuroID {
    public struct Configuration {
        var clientKey: String
        var isAdvancedDevice: Bool
        var advancedDeviceKey: String?
        var useFingerprintProxy: Bool

        public init(
            clientKey: String,
            isAdvancedDevice: Bool = false,
            advancedDeviceKey: String? = nil,
            useFingerprintProxy: Bool = false
        ) {
            self.clientKey = clientKey
            self.isAdvancedDevice = isAdvancedDevice
            self.advancedDeviceKey = advancedDeviceKey
            self.useFingerprintProxy = useFingerprintProxy
        }
    }
}
