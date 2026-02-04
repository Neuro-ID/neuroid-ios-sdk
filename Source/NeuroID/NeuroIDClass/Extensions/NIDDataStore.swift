//
//  NIDDataStore.swift
//  NeuroID
//
//  Created by Kevin Sites on 1/21/25.
//

import Foundation

extension NeuroID {
    static let IMMEDIATE_SEND_EVENT_TYPES: Set<String> = [
        NIDEventName.formSubmit.rawValue,
        NIDEventName.pageSubmit.rawValue,
        NIDEventName.setLinkedSite.rawValue,
        NIDEventName.focus.rawValue,
        NIDEventName.setRegisteredUserId.rawValue,
        NIDEventName.attemptedLogin.rawValue,
        NIDEventName.applicationMetaData.rawValue,
        NIDEventName.setUserId.rawValue,
        NIDEventName.createSession.rawValue,
        NIDEventName.advancedDevice.rawValue,
        NIDEventName.advancedDeviceRequestFailed.rawValue,
        NIDEventName.blur.rawValue,
        NIDEventName.windowBlur.rawValue,
        NIDEventName.closeSession.rawValue,
    ]

    /**
        Save and event to the datastore (logic of queue or not contained in this function)
     */
    func saveEventToDataStore(_ event: NIDEvent, screen: String? = nil) {
        if !self.isSDKStarted {
            self.saveQueuedEventToLocalDataStore(event, screen: screen)
        } else {
            self.saveEventToLocalDataStore(event, screen: screen)
        }
    }

    func saveEventToLocalDataStore(_ event: NIDEvent, screen: String? = nil) {
        if self.isStopped() {
            return
        }

        self.cleanAndStoreEvent(screen: screen ?? event.type, event: event, storeType: "event")
    }

    func saveQueuedEventToLocalDataStore(_ event: NIDEvent, screen: String? = nil) {
        self.cleanAndStoreEvent(screen: screen ?? event.type, event: event, storeType: "queue")
    }

    /**
            Method to clean incoming events, prevent unwanted events, and attach metadata fields
     */
    func cleanAndStoreEvent(screen: String, event: NIDEvent, storeType: String) {
        // If we hit a low memory event, drop events and early return
        //  OR if we are not sampling the session (i.e. are throttling)
        //  then drop events
        if self.lowMemory || !self.configService.isSessionFlowSampled {
            return
        }

        // If queue has more than config event queue size (default 2000), send a queue full event and return
        if self.datastore.getAllEventCount() > self.configService.configCache.eventQueueFlushSize {
            if self.datastore.checkLastEventType(type: NIDEventName.bufferFull.rawValue) {
                self.datastore.insertCleanedEvent(
                    event: NIDEvent(type: NIDEventName.bufferFull),
                    storeType: storeType
                )
            }
            NIDLog.debug("Warning, NeuroID DataStore is full. Event dropped: \(event.type)")
            return
        }

        let mutableEvent = event

        // Do not capture any events bound to RNScreensNavigationController as we will double count if we do
        if let eventURL = mutableEvent.url {
            if eventURL.contains("RNScreensNavigationController") {
                return
            }
        }

        // Grab the current set screen and set event URL to this
        mutableEvent.url = "ios://\(NeuroID.getScreenName() ?? "")"

        if mutableEvent.tg?["\(Constants.tgsKey.rawValue)"] != nil {
            if self.excludedViewsTestIDs.contains(where: {
                $0 == mutableEvent.tg!["\(Constants.tgsKey.rawValue)"]!.toString()
            }) {
                return
            }
        }

        // Ensure this event is not on the exclude list
        if self.excludedViewsTestIDs.contains(where: {
            $0 == mutableEvent.tgs || $0 == mutableEvent.en
        }) {
            return
        }

        let sensorManager = NIDSensorManager.shared
        mutableEvent.gyro = sensorManager.getSensorData(sensor: .gyro)
        mutableEvent.accel = sensorManager.getSensorData(sensor: .accelerometer)

        NIDLog.debug("Sensor Accel: \(sensorManager.isSensorAvailable(.accelerometer))")
        NIDLog.debug("Sensor Gyro: \(sensorManager.isSensorAvailable(.gyro))")
        NIDLog.debug("saveEvent: \(mutableEvent.toDict())")

        self.datastore.insertCleanedEvent(event: mutableEvent, storeType: storeType)

        // send on immediate on certain events regardless of SDK running collection
        if NeuroID.IMMEDIATE_SEND_EVENT_TYPES.contains(event.type) {
            self.send(forceSend: true)
        }
    }

    static func clearDataStore() {
        NeuroID.shared.datastore.forceClearAllEvents()
    }

    func moveQueuedEventsToDataStore() {
        let queuedEvents = self.datastore.getAndRemoveAllQueuedEvents()
        for event in queuedEvents {
            self.saveEventToLocalDataStore(event)
        }
    }
}
