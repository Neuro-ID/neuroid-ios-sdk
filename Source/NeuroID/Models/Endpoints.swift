//
//  Endpoints.swift
//  NeuroID
//

import Foundation

enum Endpoints {

    // MARK: - Collection Endpoints

    enum Collection {

        static func collectionURL(_ region: Region) -> URL {
            switch region {
            case .usWest:
                return URL(string: "https://edge.neuroid.cloud/usw2/c")!
            case .usEast:
                return URL(string: "https://edge.neuroid.cloud/use2/c")!
            case .usWestDefault:
                return URL(string: "https://receiver.neuroid.cloud/c")!
            }
        }
    }

    // MARK: - Device & Network Endpoints

    // FP expects type `String`, not `URL`
    enum DeviceNetwork {

        static func proxyURL(_ region: Region) -> String {
            switch region {
            case .usWest:
                return "https://dn.neuroid.cloud/iynlfqcb0t/usw2"
            case .usEast:
                return "https://dn.neuroid.cloud/iynlfqcb0t/use2"
            case .usWestDefault:
                return "https://dn.neuroid.cloud/iynlfqcb0t"
            }
        }

        static func standardURL(_ region: Region) -> String {
            switch region {
            case .usWest:
                return "https://advanced.neuro-id.com"
            case .usEast:
                return "https://advanced.neuro-id.com"
            case .usWestDefault:
                return "https://advanced.neuro-id.com"
            }
        }

        static func apiKeyURL(_ region: Region, collectionKey: String) -> URL {
            let url: URL
            switch region {
            case .usWest:
                url = URL(string: "https://edge.neuroid.cloud/usw2/a/")!
            case .usEast:
                url = URL(string: "https://edge.neuroid.cloud/use2/a/")!
            case .usWestDefault:
                url = URL(string: "https://receiver.neuroid.cloud/a/")!
            }
            return url.appendingPathComponent(collectionKey)
        }
    }

    // MARK: - Remote Config Scripts

    enum RemoteConfig {

        static func remoteConfigURL(_ region: Region, clientKey: String) -> URL {
            switch region {
            case .usWest, .usEast, .usWestDefault:
                return URL(string: "https://scripts.neuro-id.com/mobile/")!
                    .appendingPathExtension(clientKey)
                    .appendingPathExtension("json")
            }
        }
    }
}
