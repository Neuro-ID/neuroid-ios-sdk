//
//  Dictionary.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation

extension Dictionary {
    func toKeyValueString() -> String {
        return map { key, value in
            "\(key)" + "=" + "\(value)"
        }
        .joined(separator: "&")
    }
}
