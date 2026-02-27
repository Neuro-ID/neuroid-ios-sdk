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
        hostReactNativeVersion = hostRnVersion
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
        
        let useAdvancedDeviceProxy: Bool = self.getOptionValueBool(
            rnOptions: rnOptions,
            configOptionKey: .useAdvancedDeviceProxy
        )
        
        let rnVersion: String = self.getOptionValueString(
            rnOptions: rnOptions,
            configOptionKey: .hostReactNativeVersion
        )

        let configuration = NeuroID.Configuration(
            clientKey: clientKey,
            isAdvancedDevice: isAdvancedDevice,
            advancedDeviceKey: advancedDeviceKey,
            useAdvancedDeviceProxy: useAdvancedDeviceProxy
        )
            
        let configured = self.configure(configuration)

        if !configured {
            return false
        }
       
        self.setIsRN(hostRnVersion: rnVersion)
     
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
    ) -> String {
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
    case useAdvancedDeviceProxy
    case hostReactNativeVersion
    case minSdkVersion
}
