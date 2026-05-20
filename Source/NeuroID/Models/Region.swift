//
//  Region.swift
//  NeuroID
//

import Foundation

public enum Region {
    case usWest
    case usEast

    init?(configValue: String) {
        switch configValue {
        case "usEast":
            self = .usEast
        case "usWest":
            self = .usWest
        default:
            return nil
        }
    }

    var collectionUrl: URL {
        switch self {
        case .usWest:
            return Self.usWestCollectionURL
        case .usEast:
            return Self.usEastCollectionURL
        }
    }

    private static let usWestCollectionURL = URL(string: "https://receiver.neuroid.cloud/c")!
    private static let usEastCollectionURL = URL(string: "https://receiver.neuroid.cloud/c")!
    
    // FP expects type String, not URL
    var dnProxyURL: String {
        switch self {
        case .usWest:
            return Self.usWestProxyURL
        case .usEast:
            return Self.usEastProxyURL
        }
    }

    private static let usWestProxyURL = "https://dn.neuroid.cloud/iynlfqcb0t"
    private static let usEastProxyURL = "https://dn.neuroid.cloud/iynlfqcb0t"
    
    var dnStandardURL : String {
        return "https://dn.neuroid.cloud"
    }
}
