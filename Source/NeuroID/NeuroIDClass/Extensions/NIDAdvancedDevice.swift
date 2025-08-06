//
//  NIDAdvancedDevice.swift
//  NeuroID
//
//  Created by Kevin Sites on 10/13/23.
//

import Foundation

extension NeuroID {
    internal static var deviceSignalService: DeviceSignalService = AdvancedDeviceService()
    
    // flag to ensure that we only have one FPJS call in flight
    internal static var isFPJSRunning = false

    public static func start(
        _ advancedDeviceSignals: Bool,
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        NeuroID.start { started in
            if !started {
                completion(started)
                return
            }

            captureAdvancedDevice(advancedDeviceSignals)
            completion(started)
        }
    }

    public static func startSession(
        _ sessionID: String? = nil,
        _ advancedDeviceSignals: Bool,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        NeuroID.startSession(sessionID) { sessionRes in
            if !sessionRes.started {
                completion(sessionRes)
                return
            }

            captureAdvancedDevice(advancedDeviceSignals)
            completion(sessionRes)
        }
    }

    internal static func getCachedADV() -> Bool {
        if let storedADVKey = getUserDefaultKeyDict(
            Constants.storageAdvancedDeviceKey.rawValue)
        {
            if let exp = storedADVKey["exp"] as? Double,
                let requestID = storedADVKey["key"] as? String
            {
                let currentTimeEpoch = Date().timeIntervalSince1970

                if currentTimeEpoch < exp {
                    captureADVEvent(requestID, cached: true, latency: 0, message: "")
                    return true
                }
            }
        }

        return false
    }

    internal static func getNewADV() {
        // run one at a time, drop any other instances
        if (isFPJSRunning == true) {
            return
        } else {
            isFPJSRunning = true
        }
        deviceSignalService.getAdvancedDeviceSignal(
            NeuroID.clientKey ?? "",
            clientID: NeuroID.clientID,
            linkedSiteID: NeuroID.linkedSiteID,
            advancedDeviceKey: NeuroID.advancedDeviceKey
        ) { request in
            switch request {
            case .success((let requestID, let duration)):
                
                captureADVEvent(requestID, cached: false,
                                latency: duration,
                                message: advancedDeviceKey.isEmptyOrNil ? "server retrieved FPJS key" : "user entered FPJS key")
                
                setUserDefaultKey(
                    Constants.storageAdvancedDeviceKey.rawValue,
                    value: [
                        "exp": UtilFunctions.getFutureTimeStamp(configService.configCache.advancedCookieExpiration ?? NIDConfigService.DEFAULT_ADV_COOKIE_EXPIRATION),
                        "key": requestID,
                    ] as [String: Any]
                )
                isFPJSRunning = false
            case .failure(let error):
                NeuroID.saveEventToDataStore(
                    NIDEvent.createErrorLogEvent(
                        error.localizedDescription
                    )
                )
                NeuroID.saveEventToDataStore(
                    NIDEvent(
                        type: .advancedDeviceRequestFailed,
                        m: error.localizedDescription
                    )
                )
                isFPJSRunning = false
                return
            }
        }
    }

    internal static func captureADVEvent(
        _ requestID: String, cached: Bool, latency: Double, message: String
    ) {
        NeuroID.saveEventToDataStore(
            NIDEvent(
                type: .advancedDevice,
                ct: NeuroID.networkMonitor?.connectionType.rawValue,
                l: latency,
                rid: requestID,
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
    @objc internal static func captureAdvancedDevice(
        _ shouldCapture: Bool = NeuroID.isAdvancedDevice
    ) {
        NeuroID.saveEventToDataStore(
            NIDEvent.createInfoLogEvent(
                "shouldCapture setting: \(shouldCapture)"
            )
        )

        // Verify the command is called with a true value (want to capture) AND that the session
        //  is NOT being restricted/throttled prior to calling for an ADV event

        if shouldCapture,
            NeuroID.configService.isSessionFlowSampled
        {
            // call stored value, if expired then clear and get new one, else send existing
            if !getCachedADV() {
                getNewADV()
            }
        }
    }
}

