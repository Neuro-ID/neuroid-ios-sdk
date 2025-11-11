//
//  Configuration.swift
//  NeuroID
//
//  Created by Collin Dunphy on 11/4/25.
//

public struct Configuration {
    var clientKey: String
    var isAdvancedDevice: Bool
    var advancedDeviceKey: String?
    var useAdvancedDeviceProxy: Bool

    public init(
        clientKey: String,
        isAdvancedDevice: Bool = false,
        advancedDeviceKey: String? = nil,
        useAdvancedDeviceProxy: Bool = false
    ) {
        self.clientKey = clientKey
        self.isAdvancedDevice = isAdvancedDevice
        self.advancedDeviceKey = advancedDeviceKey
        self.useAdvancedDeviceProxy = useAdvancedDeviceProxy
    }
}
