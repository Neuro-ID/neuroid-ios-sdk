//
//  NIDPacketNumber.swift
//  NeuroID
//
//  Created by jeff on 7/15/24.
//

import Foundation

public extension NeuroID {
    static func getPacketNumber() -> Int32 {
        return NeuroID.shared.packetNumber
    }

    static func incrementPacketNumber() {
        NeuroID.shared.packetNumber += 1
    }
}
