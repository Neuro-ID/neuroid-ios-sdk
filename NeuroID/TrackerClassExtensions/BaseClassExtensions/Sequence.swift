//
//  Sequence.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation

extension Sequence where Element == UInt8 {
    var data: Data { .init(self) }
    var base64Decoded: Data? { Data(base64Encoded: data) }
    var string: String? { String(bytes: self, encoding: .utf8) }
}
