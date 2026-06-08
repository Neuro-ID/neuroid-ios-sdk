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
                return URL(string: "https://receiver.neuroid.cloud/c")!
            }
        }
    }

    // MARK: - Device & Network Endpoints

    // FP expects type `String`, not `URL`
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
                return "https://advanced.neuro-id.com"
            }
        }
    }

    // MARK: - Remote Config Scripts

    enum RemoteConfig {

        static func url(_ region: Region) -> URL {
            switch region {
            case .usWest:
                return URL(string: "https://scripts.neuro-id.com/mobile/")!
            }
        }
    }
}
