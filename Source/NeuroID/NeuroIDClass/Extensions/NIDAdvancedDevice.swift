//
//  NIDAdvancedDevice.swift
//  NeuroID
//
//  Created by Kevin Sites on 10/13/23.
//

import Foundation

extension NeuroIDCore {
    func start(
        _ advancedDeviceSignals: Bool,
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        self.start(siteID: nil) { started in
            if !started {
                completion(started)
                return
            }

            self.captureAdvancedDevice(advancedDeviceSignals)
            completion(started)
        }
    }

    func startSession(
        _ identityId: String? = nil,
        _ advancedDeviceSignals: Bool,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        self.startSession(siteID: nil, identityId: identityId) { sessionRes in
            if !sessionRes.started {
                completion(sessionRes)
                return
            }

            self.captureAdvancedDevice(advancedDeviceSignals)
            completion(sessionRes)
        }
    }

    func getCachedADV() -> Bool {
        guard
            let eventId = getUserDefaultKeyString(Constants.storageAdvancedDeviceKey.rawValue),
            let requestTimestamp = UtilFunctions.getTimestampFromEventId(eventId)
        else {
            return false
        }

        let age = Date().timeIntervalSince(requestTimestamp)
        let cacheValidity = TimeInterval(ConfigService.DEFAULT_ADV_COOKIE_EXPIRATION)
        let maxAge = TimeInterval(ConfigService.DEFAULT_ADV_MAX_AGE)

        // Still within the cache window, reuse the existing request
        if age < cacheValidity {
            self.captureADVEvent(eventId, cached: true, latency: 0)
            return true
        }

        // Cache has expired but the request is still recent enough to be
        // meaningful, send it one last time before fetching a new one
        if age < maxAge {
            self.captureADVEvent(eventId, cached: true, latency: 0)
        }

        // Either just expired or too stale to send - a new request is needed
        return false
    }

    func getNewADV() {
        // run one at a time, drop any other instances
        guard !self.isFPJSRunning else {
            return
        }

        self.isFPJSRunning = true

        self.deviceSignalService.getAdvancedDeviceSignal(
            self.getClientKey(),
            advancedDeviceKey: self.advancedDeviceKey
        ) { request in
            switch request {
            case .success((let eventId, let duration)):

                self.captureADVEvent(
                    eventId,
                    cached: false,
                    latency: duration,
                    message: self.advancedDeviceKey.isEmptyOrNil ? "server retrieved FPJS key" : "user entered FPJS key"
                )

                setUserDefaultKey(Constants.storageAdvancedDeviceKey.rawValue, value: eventId)

                self.isFPJSRunning = false

            case .failure(let error):
                self.saveEventToDataStore(
                    NIDEvent.createErrorLogEvent(
                        error.localizedDescription
                    )
                )

                self.saveEventToDataStore(
                    NIDEvent(
                        type: .advancedDeviceRequestFailed,
                        m: error.localizedDescription
                    )
                )

                self.isFPJSRunning = false

                return
            }
        }
    }

    func captureADVEvent(
        _ eventId: String,
        cached: Bool,
        latency: Double,
        message: String? = nil
    ) {
        self.saveEventToDataStore(
            NIDEvent(
                type: .advancedDevice,
                ct: NeuroIDCore.shared.networkMonitor.connectionType,
                l: latency,
                rid: eventId,
                c: cached,
                m: message
            )
        )
    }

    /**
     Based on the parameter passed in AND the sampling flag, this function will make a call to the ADV library or not,
     Default is to use the global settings from the NeuroID class but can be overridden (see `start`
     or `startSession` in the `NIDAdvancedDevice.swift` file.

     Marked as `@objc` because this method can be called with reflection if the ADV library is not installed.
     Because of the reflection we use an array with a boolean instead of just boolean. Log the shouldCapture flag
     in a LOG event (isAdvancedDevice setting: <true/false>.
     */
    @objc func captureAdvancedDevice(
        _ shouldCapture: Bool
    ) {
        self.saveEventToDataStore(
            NIDEvent.createInfoLogEvent(
                "shouldCapture setting: \(shouldCapture)"
            )
        )

        // Verify the command is called with a true value (want to capture) AND that the session
        //  is NOT being restricted/throttled prior to calling for an ADV event
        if shouldCapture && self.configService.isSessionFlowSampled && !self.getCachedADV() {
            self.getNewADV()
        }
    }
}
