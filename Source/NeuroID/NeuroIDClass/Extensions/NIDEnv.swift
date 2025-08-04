//
//  NIDEnv.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation

public extension NeuroID {
    static func getEnvironment() -> String {
        return environment
    }

    @available(*, deprecated, message: "setEnvironmentProduction is deprecated and no longer required")
    static func setEnvironmentProduction(_ value: Bool) {
        logger.i("**** NOTE: THIS METHOD IS DEPRECATED")
    }
}
