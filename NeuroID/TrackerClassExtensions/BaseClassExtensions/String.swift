//
//  String.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation

extension String {
    func decodeBase64() -> [String: Any]? {
        guard let decodedData = Data(base64Encoded: self) else { return nil }

        do {
            let dict = try JSONSerialization.jsonObject(with: decodedData, options: .allowFragments)
            return dict as? [String: Any]
        } catch {
            return nil
        }
    }

    func compareDescriptions(_ descriptions: [String]) -> Bool {
        let currentLocation = components(separatedBy: ";")[0]
        for desc in descriptions {
            let oldLocation = desc.components(separatedBy: ";")[0]
            if currentLocation == oldLocation {
                return true
            }
        }

        return false
    }
}

public extension String {
    func sha256() -> String {
        var saltedString = self + UUID().uuidString
        if let stringData = saltedString.data(using: String.Encoding.utf8) {
            return stringData.sha256()
        }
        return ""
    }
}

/** Base 64 Encode/Decoding
 */
extension StringProtocol {
    var data: Data { Data(utf8) }
    var base64Encoded: Data { data.base64EncodedData() }
    var base64Decoded: Data? { Data(base64Encoded: string) }
}
