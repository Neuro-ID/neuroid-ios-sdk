//
//  Endpoints.swift
//  NeuroID
//

import Foundation

enum Endpoints {
    
    // MARK: - Collection Endpoints
    
    enum Collection {

        static func url(_ region: Region) -> URL {
            switch region {
            case .usWest:
                return Self.usWestCollectionURL
            }
        }

        private static let usWestCollectionURL = URL(string: "https://receiver.neuroid.cloud/c")!
    }

    // MARK: - Device & Network Endpoints
    
    /// Device & Network Endpoints
    ///
    /// FP expects type `String`, not `URL`
    enum DeviceNetwork {
        
        static func proxyUrl(_ region: Region) -> String {
            switch region {
            case .usWest:
                return "https://dn.neuroid.cloud/iynlfqcb0t"
            }
        }
        
        static func standardURL(_ region: Region) -> String {
            switch region {
            case .usWest:
                return "https://dn.neuroid.cloud"
            }
        }
    }
}
