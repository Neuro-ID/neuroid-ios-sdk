//
//  Collection.swift
//  NeuroID
//
//  Created by Kevin Sites on 8/31/23.
//

import Foundation

extension Collection where Iterator.Element == [String: Any?] {
    func toJSONString() -> String {
        if let arr = self as? [[String: Any?]],
           let dat = try? JSONSerialization.data(withJSONObject: arr),
           let str = String(data: dat, encoding: String.Encoding.utf8)
        {
            return str
        }
        return "[]"
    }
}

extension Collection where Iterator.Element == NIDEvent {
    func toArrayOfDicts() -> [[String: Any?]] {
        let dat = self.map { $0.asDictionary.mapValues { value in
            value
        } }

        return dat
    }
}
