//
//  NIDListeners.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/14/24.
//

import Foundation

extension NeuroID {
    static func createListeners() {
        if configService.configCache.callInProgress {
            callObserver = NIDCallStatusObserver()
        }

        if configService.configCache.geoLocation {
            locationManager = LocationManager()
        }

        if configService.configCache.gyroAccelCadence {
            sendGyroAccelCollectionWorkItem = createGyroAccelCollectionWorkItem()
        }
    }
}
