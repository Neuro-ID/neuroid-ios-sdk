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

    static func setEnvironmentProduction(_ value: Bool) {
        NIDPrintLog("**** NeuroID NOTE: THIS METHOD IS DEPRECATED")
    }
}
