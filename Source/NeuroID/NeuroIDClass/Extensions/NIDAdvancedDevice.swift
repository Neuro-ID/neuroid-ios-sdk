//
//  NIDAdvancedDevice.swift
//  NeuroID
//
//  Created by Kevin Sites on 10/13/23.
//

import Foundation

extension NeuroID {
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
        _ sessionID: String? = nil,
        _ advancedDeviceSignals: Bool,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        self.startSession(siteID: nil, sessionID: sessionID) { sessionRes in
            if !sessionRes.started {
                completion(sessionRes)
                return
            }

            self.captureAdvancedDevice(advancedDeviceSignals)
            completion(sessionRes)
        }
    }

    func getCachedADV() -> Bool {
        if let storedADVKey = getUserDefaultKeyDict(Constants.storageAdvancedDeviceKey.rawValue) {
            if let exp = storedADVKey["exp"] as? Double, let requestID = storedADVKey["key"] as? String {
                let currentTimeEpoch = Date().timeIntervalSince1970

                if currentTimeEpoch < exp {
                    // If there is sealed results from Fingerprint proxy, include those
                    let storedSealedResults: String? = storedADVKey["scr"] as? String

                    self.captureADVEvent(requestID, cached: true, latency: 0, message: "", sealedClientResults: storedSealedResults)
                    return true
                }
            }
        }

        return false
    }

    func getNewADV() {
        // run one at a time, drop any other instances
        if self.isFPJSRunning == true {
            return
        } else {
            self.isFPJSRunning = true
        }
        self.deviceSignalService.getAdvancedDeviceSignal(
            self.getClientKey(),
            clientID: self.clientID,
            linkedSiteID: self.linkedSiteID,
            advancedDeviceKey: self.advancedDeviceKey
        ) { request in
            switch request {
            case .success((let requestID, let duration, let sealedClientResults)):

                self.captureADVEvent(
                    requestID,
                    cached: false,
                    latency: duration,
                    message: self.advancedDeviceKey.isEmptyOrNil ? "server retrieved FPJS key" : "user entered FPJS key",
                    sealedClientResults: sealedClientResults
                )

                setUserDefaultKey(
                    Constants.storageAdvancedDeviceKey.rawValue,
                    value: [
                        "exp": UtilFunctions.getFutureTimeStamp(
                            self.configService.configCache.advancedCookieExpiration ?? NIDConfigService.DEFAULT_ADV_COOKIE_EXPIRATION
                        ),
                        "key": requestID,
                        "scr": sealedClientResults,
                    ] as [String: Any?]
                )

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
        _ requestID: String,
        cached: Bool,
        latency: Double,
        message: String,
        sealedClientResults: String? = nil
    ) {
        self.saveEventToDataStore(
            NIDEvent(
                type: .advancedDevice,
                ct: NeuroID.shared.networkMonitor.connectionType,
                l: latency,
                rid: requestID,
                c: cached,
                m: message,
                sealedClientResults: sealedClientResults
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
