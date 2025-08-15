//
//  NIDListeners.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/14/24.
//

import Foundation

extension NeuroID {
    static func setupListeners() {
        // We will always cancel the collection job and then recreate with new interval and start
        sendCollectionEventsJob.cancel()
        sendCollectionEventsJob = RepeatingTask(
            interval: Double(NeuroID.shared.configService.configCache.eventQueueFlushInterval),
            task: NeuroID.sendCollectionEventsTask
        )
        sendCollectionEventsJob.start()

        if NeuroID.shared.configService.configCache.callInProgress {
            NeuroID.shared.callObserver = NIDCallStatusObserverService(
                eventStorageService: NeuroID.shared.eventStorageService,
                configService: NeuroID.shared.configService
            )
            NeuroID.shared.callObserver?.startListeningToCallStatus()
        } else {
            NeuroID.shared.callObserver = nil
        }

        if NeuroID.shared.configService.configCache.geoLocation {
            NeuroID.shared.locationManager = LocationManagerService()
        } else {
            NeuroID.shared.locationManager = nil
        }

        // We will always cancel the current gyro job and then if the config allows we will recreate and start
        //  with new interval value
        NeuroID.sendGyroAccelCollectionWorkItem.cancel()
        if NeuroID.shared.configService.configCache.gyroAccelCadence {
            NeuroID.sendGyroAccelCollectionWorkItem = RepeatingTask(
                interval: Double(NeuroID.shared.configService.configCache.gyroAccelCadenceTime),
                task: NeuroID.collectGyroAccelEventTask
            )

            NeuroID.sendGyroAccelCollectionWorkItem.start()
        }
    }
}
