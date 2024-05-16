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
        deviceSignalService.getAdvancedDeviceSignal(NeuroID.clientKey ?? "") { request in
            switch request {
            case .success((let requestID, let duration)):

                captureADVEvent(requestID, cached: false, latency: duration)
                    
                setUserDefaultKey(
                    Constants.storageAdvancedDeviceKey.rawValue,
                    value: ["exp": UtilFunctions.getFutureTimeStamp(24),
                            "key": requestID] as [String: Any]
                )
            case .failure(let error):
                let nidEvent = NIDEvent(type: .log)
                nidEvent.m = error.localizedDescription
                nidEvent.level = "ERROR"
                    
                NeuroID.saveEventToLocalDataStore(nidEvent)
                return
            }
        }
    }
    
    internal static func captureADVEvent(_ requestID: String, cached: Bool, latency: Double) {
        let nidEvent = NIDEvent(type: .advancedDevice)
        nidEvent.rid = requestID
        nidEvent.c = cached
        nidEvent.l = latency
        nidEvent.ct = NeuroID.networkMonitor?.connectionType.rawValue
            
        NeuroID.saveEventToLocalDataStore(nidEvent)
    }
    
    @objc internal static func captureAdvancedDevice(_ shouldCapture: [Bool] = [NeuroID.isAdvancedDevice]) {
        if shouldCapture.indices.contains(0), shouldCapture[0] {
            // call stored value, if expired then clear and get new one, else send existing
            if !getCachedADV() {
                getNewADV()
            }
        }
    }
}
