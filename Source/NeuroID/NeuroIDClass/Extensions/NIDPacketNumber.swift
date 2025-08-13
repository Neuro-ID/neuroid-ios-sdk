//
//  NIDPacketNumber.swift
//  NeuroID
//
//  Created by jeff on 7/15/24.
//

import Foundation

public extension NeuroID {
    static func getPacketNumber() -> Int32 {
        return packetNumber
    }

    static func incrementPacketNumber() {
        packetNumber += 1
    }
}
