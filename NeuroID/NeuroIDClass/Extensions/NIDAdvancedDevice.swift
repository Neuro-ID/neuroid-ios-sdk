//
//  NIDAdvancedDevice.swift
//  NeuroID
//
//  Created by Kevin Sites on 10/13/23.
//

import Foundation
import NeuroIDAdvancedDevice

public extension NeuroID {
    static func start(_ advancedDeviceSignals: Bool) -> Bool {
        let started = NeuroID.start()
        
        if !started {
            return started
        }
       
        if advancedDeviceSignals {
            // call stored value, if expired then clear and get new one, else send existing
            if !getCachedADV() {
                getNewADV()
            }
        }
        
        return started
    }
    
    static func startSession(_ sessionID: String? = nil, _ advancedDeviceSignals: Bool) -> (Bool, String) {
        let (started, id) = NeuroID.startSession(sessionID)
        
        if !started {
            return (started, id)
        }
       
        if advancedDeviceSignals {
            // call stored value, if expired then clear and get new one, else send existing
            if !getCachedADV() {
                getNewADV()
            }
        }
        
        return (started, id)
    }
    
    internal static func getCachedADV() -> Bool {
        if let storedADVKey = getUserDefaultKeyDict(Constants.storageAdvancedDeviceKey.rawValue) {
            if let exp = storedADVKey["exp"] as? Double, let requestID = storedADVKey["key"] as? String {
                let currentTimeEpoch = Date().timeIntervalSince1970
                
                if currentTimeEpoch < exp {
                    captureADVEvent(requestID, cached: true)
                    return true
                }
            }
        }
        
        return false
    }
    
    internal static func getNewADV() {
        NeuroIDADV.getAdvancedDeviceSignal(NeuroID.clientKey ?? "") { request in
            switch request {
            case .success(let requestID):
                captureADVEvent(requestID, cached: false)
                    
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
    
    internal static func captureADVEvent(_ requestID: String, cached: Bool) {
        let nidEvent = NIDEvent(type: .advancedDevice)
        nidEvent.rid = requestID
        nidEvent.c = cached
            
        NeuroID.saveEventToLocalDataStore(nidEvent)
    }
}
