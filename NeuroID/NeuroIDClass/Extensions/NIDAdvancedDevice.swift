//
//  NIDAdvancedDevice.swift
//  NeuroID
//
//  Created by Kevin Sites on 10/13/23.
//

import Foundation
import NeuroIDAdvancedDevice

public extension NeuroID {
    static func start(advancedDeviceSignals: Bool) {
        NeuroID.start()
        
        if advancedDeviceSignals {
            // call stored value, if expired then clear and get new one, else send existing
            if let storedADVKey = getUserDefaultKeyDict(Constants.storageAdvancedDeviceKey.rawValue) {
                if let exp = storedADVKey["exp"] as? Double, let requestID = storedADVKey["key"] as? String {
                    let currentTimeEpoch = Date().timeIntervalSince1970
                    
                    if currentTimeEpoch < exp {
                        let nidEvent = NIDEvent(type: .advancedDevice)
                        nidEvent.rid = requestID
                        nidEvent.c = true
                        
                        NeuroID.saveEventToLocalDataStore(nidEvent)
                        return
                    }
                }
            }
            
            NeuroIDADV.getAdvancedDeviceSignal(NeuroID.clientKey ?? "") { request in
                switch request {
                case .success(let requestID):
                    let nidEvent = NIDEvent(type: .advancedDevice)
                    nidEvent.rid = requestID
                    nidEvent.c = false
                        
                    NeuroID.saveEventToLocalDataStore(nidEvent)
                        
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
    }
}
