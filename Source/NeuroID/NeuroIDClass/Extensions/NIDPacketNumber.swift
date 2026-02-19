//
//  NIDPacketNumber.swift
//  NeuroID
//
//  Created by jeff on 7/15/24.
//

import Foundation

extension NeuroIDCore {
    func getPacketNumber() -> Int32 {
        return self.packetNumber
    }

    func incrementPacketNumber() {
        self.packetNumber += 1
    }
}
