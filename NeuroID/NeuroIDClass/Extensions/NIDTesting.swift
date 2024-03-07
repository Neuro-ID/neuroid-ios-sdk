//
//  NIDTesting.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/7/24.
//

import Foundation

public extension NeuroID {
    // MARK: Used for Testing Only

    static func setDevTestingURL() {
        NeuroID.collectionURL = Constants.developmentURL.rawValue
    }
}
