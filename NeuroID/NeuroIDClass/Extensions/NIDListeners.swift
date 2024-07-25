//
//  NIDListeners.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/14/24.
//

import Foundation

extension NeuroID {
    static func setupListeners() {
        if configService.configCache.callInProgress {
            callObserver = NIDCallStatusObserver()
            callObserver?.startListeningToCallStatus()
        } else {
            callObserver = nil
        }

        if configService.configCache.geoLocation {
            locationManager = LocationManager()
        } else {
            locationManager = nil
        }

        if configService.configCache.gyroAccelCadence {
            sendGyroAccelCollectionWorkItem = createGyroAccelCollectionWorkItem()
        } else {
            sendGyroAccelCollectionWorkItem?.cancel()
            sendGyroAccelCollectionWorkItem = nil
        }
    }
}
