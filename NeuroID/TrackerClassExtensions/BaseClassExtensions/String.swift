//
//  String.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation

internal extension String {
    func sha256() -> String {
        var existingSalt = UserDefaults.standard.string(forKey: Constants.storageSaltKey.rawValue) ?? ""

        if existingSalt == "" {
            existingSalt = UUID().uuidString
            UserDefaults.standard.set(existingSalt, forKey: Constants.storageSaltKey.rawValue)
        }

        let saltedString = self + existingSalt
        if let stringData = saltedString.data(using: String.Encoding.utf8) {
            return stringData.sha256()
        }
        return ""
    }

    func hashValue() -> String {
        return sha256().prefix(8).string
    }
}
