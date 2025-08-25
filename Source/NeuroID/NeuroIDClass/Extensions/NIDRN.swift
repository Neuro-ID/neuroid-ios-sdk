//
//  NIDRN.swift
//  NeuroID
//
//  Created by Kevin Sites on 9/26/23.
//

import Foundation

extension NeuroID {
    func setIsRN() {
        isRN = true
    }

    func configure(clientKey: String, rnOptions: [String: Any]) -> Bool {
        let isAdvancedDevice = self.getOptionValueBool(
            rnOptions: rnOptions,
            configOptionKey: .isAdvancedDevice
        )
        let advancedDeviceKey = self.getOptionValueString(
            rnOptions: rnOptions,
            configOptionKey: .advancedDeviceKey
        )

        let configured = self.configure(
            clientKey: clientKey, isAdvancedDevice: isAdvancedDevice, advancedDeviceKey: advancedDeviceKey
        )

        if !configured {
            return false
        }

        self.setIsRN()

        // Extract RN Options and put them in NeuroID Class Dict to be referenced
        let usingReactNavigation = self.getOptionValueBool(
            rnOptions: rnOptions,
            configOptionKey: .usingReactNavigation
        )

        self.rnOptions[.usingReactNavigation] = usingReactNavigation

        return true
    }

    func getOptionValueBool(
        rnOptions: [String: Any], configOptionKey: RNConfigOptions
    ) -> Bool {
        if let configValue = rnOptions[configOptionKey.rawValue] as? Bool {
            return configValue
        }

        return false
    }

    func getOptionValueString(
        rnOptions: [String: Any], configOptionKey: RNConfigOptions
    ) -> String? {
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
