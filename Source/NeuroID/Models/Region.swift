//
//  Region.swift
//  NeuroID
//

import Foundation

public enum Region {
    case usWest

    init?(configValue: String) {
        switch configValue {
        case "usWest":
            self = .usWest
        default:
            return nil
        }
    }
}
