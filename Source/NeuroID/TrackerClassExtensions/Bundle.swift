//
//  Bundle.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import os

extension Bundle {
    static func infoPlistValue(forKey key: String) -> Any? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) else {
            os_log("NeuroID Failed to find Plist")
            return nil
        }
        os_log("NeuroID config found")
        return value
    }
}
