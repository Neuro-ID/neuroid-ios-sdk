//
//  NIDListeners.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/14/24.
//

import Foundation

extension NeuroIDCore {
    func setupListeners() {
        // We will always cancel the collection job and then recreate with new interval and start
        self.sendCollectionEventsJob.cancel()
        self.sendCollectionEventsJob = RepeatingTask(
            interval: Double(self.configService.configCache.eventQueueFlushInterval),
            task: NeuroIDCore.sendCollectionEventsTask
        )
        self.sendCollectionEventsJob.start()

        if self.configService.configCache.callInProgress {
            self.callObserver = NIDCallStatusObserverService(
                eventStorageService: self.eventStorageService,
                configService: self.configService
            )
            self.callObserver?.startListeningToCallStatus()
        } else {
            self.callObserver = nil
        }

        if self.configService.configCache.geoLocation {
            self.locationManager = LocationManagerService()
        } else {
            self.locationManager = nil
        }

        // We will always cancel the current gyro job and then if the config allows we will recreate and start
        //  with new interval value
        self.collectGyroAccelEventJob.cancel()
        if self.configService.configCache.gyroAccelCadence {
            self.collectGyroAccelEventJob = RepeatingTask(
                interval: Double(self.configService.configCache.gyroAccelCadenceTime),
                task: NeuroIDCore.collectGyroAccelEventTask
            )

            self.collectGyroAccelEventJob.start()
        }
    }
}
