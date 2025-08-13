//
//  NIDSend.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Alamofire
import Foundation

extension NeuroID {
    static func initTimer() {
        // Send up the first payload, and then setup a repeating timer
        DispatchQueue
            .global(qos: .utility)
            .asyncAfter(deadline: .now() + Double(NeuroID.configService.configCache.eventQueueFlushInterval)) {
                self.send()
                self.initTimer()
            }
    }

    static func initCollectionTimer() {
        if let workItem = NeuroID.sendCollectionWorkItem {
            // Send up the first payload, and then setup a repeating timer
            DispatchQueue
                .global(qos: .utility)
                .asyncAfter(
                    deadline: .now() + SEND_INTERVAL,
                    execute: workItem
                )
        }
    }

    static func createCollectionWorkItem() -> DispatchWorkItem {
        let workItem = DispatchWorkItem {
            guard !(NeuroID.sendCollectionWorkItem?.isCancelled ?? false) else {
                return
            }

            if !NeuroID.isStopped() {
                self.send()
                self.initCollectionTimer()
            }
        }

        return workItem
    }

    static func initGyroAccelCollectionTimer() {
        // If gyro cadence not enabled, early return
        if !NeuroID.configService.configCache.gyroAccelCadence {
            return
        }
        if let workItem = NeuroID.sendGyroAccelCollectionWorkItem {
            // Send up the first payload, and then setup a repeating timer
            DispatchQueue
                .global(qos: .utility)
                .asyncAfter(
                    deadline: .now() + Double(NeuroID.configService.configCache.gyroAccelCadenceTime),
                    execute: workItem
                )
        }
    }

    static func createGyroAccelCollectionWorkItem() -> DispatchWorkItem {
        let workItem = DispatchWorkItem {
            guard !(NeuroID.sendGyroAccelCollectionWorkItem?.isCancelled ?? false) else {
                return
            }

            if !NeuroID.isStopped() {
                let nidEvent = NIDEvent(type: .cadenceReadingAccel)
                nidEvent.attrs = [
                    Attrs(n: "interval", v: "\(NeuroID.configService.configCache.gyroAccelCadenceTime)ms"),
                ]

                NeuroID.saveEventToLocalDataStore(nidEvent)

                self.initGyroAccelCollectionTimer()
            }
        }

        return workItem
    }

    static func send(
        forceSend: Bool = false,
        eventSubset: [NIDEvent]? = nil,
        completion: @escaping () -> Void = {}
    ) {
        if NeuroID._isTesting {
            return
        }

        if !NeuroID.isStopped() || forceSend {
            DispatchQueue.global(qos: .utility).async {
                NeuroID.payloadSendingService.cleanAndSendEvents(
                    clientKey: NeuroID.getClientKey(),
                    screenName: NeuroID.getScreenName(),
                    onPacketIncrement: { NeuroID.incrementPacketNumber() },
                    onSuccess: completion,
                    onFailure: { error in
                        NeuroID.saveEventToDataStore(
                            NIDEvent.createErrorLogEvent("Group and POST failure: \(error)")
                        )

                        completion()
                    },
                    eventSubset: eventSubset
                )
            }
        }
    }
}
