//
//  NIDRN.swift
//  NeuroID
//
//  Created by Kevin Sites on 9/26/23.
//

import Foundation

extension NeuroIDCore {

    func setIsRN(hostRnVersion: String) {
        isRN = true
        rnVersion = hostRnVersion
    }

    func configure(clientKey: String, rnOptions: [String: Any]) -> Bool {
        let isAdvancedDevice: Bool? = rnOptions[RNConfigOptions.isAdvancedDevice.rawValue] as? Bool
        let advancedDeviceKey: String? = rnOptions[RNConfigOptions.advancedDeviceKey.rawValue] as? String
        let useAdvancedDeviceProxy: Bool? = rnOptions[RNConfigOptions.useAdvancedDeviceProxy.rawValue] as? Bool

        let configuration = NeuroID.Configuration(
            clientKey: clientKey,
            isAdvancedDevice: isAdvancedDevice,
            advancedDeviceKey: advancedDeviceKey,
            useAdvancedDeviceProxy: useAdvancedDeviceProxy
        )

        // Extract RN Version
        let rnVersion: String = rnOptions[RNConfigOptions.rnVersion.rawValue] as? String ?? ""
        self.setIsRN(hostRnVersion: rnVersion)

        // Extract RN Options and put them in NeuroID Class Dict to be referenced
        let usingReactNavigation: Bool = rnOptions[RNConfigOptions.usingReactNavigation.rawValue] as? Bool ?? false
        self.rnOptions[.usingReactNavigation] = usingReactNavigation

        return self.configure(configuration)
    }
}

enum RNConfigOptions: String {
    case usingReactNavigation
    case isAdvancedDevice
    case advancedDeviceKey
    case useAdvancedDeviceProxy
    case rnVersion
}
