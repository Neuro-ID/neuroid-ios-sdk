//
//  NIDAdvancedDevice.swift
//  NeuroID
//
//  Created by Kevin Sites on 10/13/23.
//

import Foundation
import NeuroIDAdvancedDevice

public extension NeuroID {
    internal static var deviceSignalService: DeviceSignalService = NeuroIDADV()

    static func start(
        _ advancedDeviceSignals: Bool,
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        NeuroID.start { started in
            if !started {
                completion(started)
                return
            }
                   
            checkThenCaptureAdvancedDevice(advancedDeviceSignals)
            completion(started)
        }
    }
    
    static func startSession(
        _ sessionID: String? = nil,
        _ advancedDeviceSignals: Bool,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        NeuroID.startSession(sessionID) { sessionRes in
            if !sessionRes.started {
                completion(sessionRes)
                return
            }
                   
            checkThenCaptureAdvancedDevice(advancedDeviceSignals)
            completion(sessionRes)
        }
    }
    
    internal static func getCachedADV() -> Bool {
        if let storedADVKey = getUserDefaultKeyDict(Constants.storageAdvancedDeviceKey.rawValue) {
            if let exp = storedADVKey["exp"] as? Double, let requestID = storedADVKey["key"] as? String {
                let currentTimeEpoch = Date().timeIntervalSince1970
                
                if currentTimeEpoch < exp {
                    captureADVEvent(requestID, cached: true, latency: 0)
                    return true
                }
            }
        }
        
        return false
    }
    
    internal static func getNewADV() {
        deviceSignalService.getAdvancedDeviceSignal(
            NeuroID.clientKey ?? "",
            clientID: NeuroID.clientID,
            linkedSiteID: NeuroID.linkedSiteID
        ) { request in
            switch request {
            case .success((let requestID, let duration)):

                captureADVEvent(requestID, cached: false, latency: duration)
                    
                setUserDefaultKey(
                    Constants.storageAdvancedDeviceKey.rawValue,
                    value: ["exp": UtilFunctions.getFutureTimeStamp(24),
                            "key": requestID] as [String: Any]
                )
            case .failure(let error):
                NeuroID.saveEventToLocalDataStore(
                    NIDEvent(type: .log, level: "ERROR", m: error.localizedDescription)
                )
                return
            }
        }
    }
    
    internal static func captureADVEvent(_ requestID: String, cached: Bool, latency: Double) {
        NeuroID.saveEventToLocalDataStore(
            NIDEvent(
                type: .advancedDevice,
                ct: NeuroID.networkMonitor?.connectionType.rawValue,
                l: latency,
                rid: requestID,
                c: cached
            )
        )
    }
    
    /**
     Based on the parameter passed in AND the sampling flag, this function will make a call to the ADV library or not,
     Default is to use the global settings from the NeuroID class but can be overridden (see `start`
     or `startSession` in the `NIDAdvancedDevice.swift` file.
     
     Marked as `@objc` because this method can be called with reflection if the ADV library is not installed.
     Because of the reflection we use an array with a boolean instead of just boolean
     */
    @objc internal static func captureAdvancedDevice(
        _ shouldCapture: [Bool] = [NeuroID.isAdvancedDevice]
    ) {
        // Verify the command is called with a true value (want to capture) AND that the session
        //  is NOT being restricted/throttled prior to calling for an ADV event
        
        if shouldCapture.indices.contains(0),
           shouldCapture[0],
           NeuroID.samplingService.isSessionFlowSampled
        {
            // call stored value, if expired then clear and get new one, else send existing
            if !getCachedADV() {
                getNewADV()
            }
        }
    }
}
