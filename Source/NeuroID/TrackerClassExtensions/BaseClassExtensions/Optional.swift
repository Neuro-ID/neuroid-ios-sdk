//
//  Optional.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/26/23.
//

import Foundation

extension Optional where Wrapped: Collection {
    var isEmptyOrNil: Bool {
        guard let value = self else { return true }
        return value.isEmpty
    }
}
