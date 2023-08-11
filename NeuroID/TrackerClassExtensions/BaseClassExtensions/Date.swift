//
//  Date.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/26/23.
//

import Foundation

internal extension Date {
    func toString() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
        let dpValue = df.string(from: self)

        return dpValue
    }
}
