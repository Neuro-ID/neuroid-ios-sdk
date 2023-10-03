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

    static func configure(clientKey: String, rnOptions: [String: Any]) {
        configure(clientKey: clientKey)
        setIsRN()

        // Extract RN Options and put them in NeuroID Class Dict to be referenced
        let usingReactNavigation = getOptionValueBool(
            rnOptions: rnOptions,
            configOptionKey: .usingReactNavigation
        )

        self.rnOptions[.usingReactNavigation] = usingReactNavigation
    }

    static func getOptionValueBool(rnOptions: [String: Any], configOptionKey: RNConfigOptions) -> Bool {
        if let configValue = rnOptions[configOptionKey.rawValue] as? Bool {
            return configValue
        }

        return false
    }
}

public enum RNConfigOptions: String, Hashable {
    case usingReactNavigation
}
