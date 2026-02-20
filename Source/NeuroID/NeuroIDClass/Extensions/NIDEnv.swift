//
//  NIDEnv.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation

extension NeuroIDCore {
    func getEnvironment() -> String {
        return self.environment
    }

    @available(
        *, deprecated, message: "setEnvironmentProduction is deprecated and no longer required"
    )
    static func setEnvironmentProduction(_ value: Bool) {
        NIDLog.info("**** NOTE: THIS METHOD IS DEPRECATED")
    }
}
