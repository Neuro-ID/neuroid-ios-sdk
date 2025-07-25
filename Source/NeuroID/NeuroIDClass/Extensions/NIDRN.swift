//
//  NIDRN.swift
//  NeuroID
//
//  Created by Kevin Sites on 9/26/23.
//

import Foundation

public extension NeuroID {
    static func setIsRN() {
        isRN = true
    }

    static func configure(clientKey: String, rnOptions: [String: Any]) -> Bool {
        let isAdvancedDevice = getOptionValueBool(
            rnOptions: rnOptions,
            configOptionKey: .isAdvancedDevice
        )
        let advancedDeviceKey = getOptionValueString(
            rnOptions: rnOptions,
            configOptionKey: .advancedDeviceKey
        )
        
        let configured = configure(clientKey: clientKey, isAdvancedDevice: isAdvancedDevice, advancedDeviceKey: advancedDeviceKey)

        if !configured {
            return false
        }

        setIsRN()

        // Extract RN Options and put them in NeuroID Class Dict to be referenced
        let usingReactNavigation = getOptionValueBool(
            rnOptions: rnOptions,
            configOptionKey: .usingReactNavigation
        )

        self.rnOptions[.usingReactNavigation] = usingReactNavigation

        return true
    }

    internal static func getOptionValueBool(rnOptions: [String: Any], configOptionKey: RNConfigOptions) -> Bool {
        if let configValue = rnOptions[configOptionKey.rawValue] as? Bool {
            return configValue
        }
        
        return false
    }
    
    internal static func getOptionValueString(rnOptions: [String: Any], configOptionKey: RNConfigOptions) -> String? {
        guard let configValue = rnOptions[configOptionKey.rawValue] as? String else {
            return ""
        }
        return configValue as String
    }
}

public enum RNConfigOptions: String, Hashable {
    case usingReactNavigation
    case isAdvancedDevice
    case advancedDeviceKey
}
