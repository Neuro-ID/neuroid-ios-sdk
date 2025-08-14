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
            interval: Double(NeuroID.configService.configCache.eventQueueFlushInterval),
            task: NeuroID.sendCollectionEventsTask
        )
        sendCollectionEventsJob.start()

        if configService.configCache.callInProgress {
            callObserver = NIDCallStatusObserverService(
                eventStorageService: NeuroID.eventStorageService,
                configService: NeuroID.configService
            )
            callObserver?.startListeningToCallStatus()
        } else {
            callObserver = nil
        }

        if configService.configCache.geoLocation {
            locationManager = LocationManagerService()
        } else {
            locationManager = nil
        }

        // We will always cancel the current gyro job and then if the config allows we will recreate and start
        //  with new interval value
        NeuroID.sendGyroAccelCollectionWorkItem.cancel()
        if configService.configCache.gyroAccelCadence {
            NeuroID.sendGyroAccelCollectionWorkItem = RepeatingTask(
                interval: Double(NeuroID.configService.configCache.gyroAccelCadenceTime),
                task: NeuroID.collectGyroAccelEventTask
            )

            NeuroID.sendGyroAccelCollectionWorkItem.start()
        }
    }
}
