//
//  Region.swift
//  NeuroID
//

import Foundation

public enum Region: String, Sendable {

    // Original region endpoints in usw2
    case usWestDefault

    // Updated endpoints for usw2 and use2
    case usWest, usEast

    // Initalizer for React Native passed values
    init?(rnValue: String) {
        switch rnValue {
        case "US_WEST":
            self = .usWest
        case "US_EAST":
            self = .usEast
        case "US_WEST_DEFAULT":
            self = .usWestDefault
        default:
            return nil
        }
    }
}
