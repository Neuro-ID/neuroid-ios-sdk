//
//  NIDConfigService.swift
//  NeuroID

import Foundation
import Alamofire

internal class NIDConfigService {
    
    struct ResponseData: Decodable {
        var callInProgress: Bool
        var eventQueueFlushInterval: Int
        var eventQueueFlushSize: Int
        var geoLocation: Bool
        var gyroAccelCadence: Bool
        var gyroAccelCadenceTime: Int
        var requestTimeout: Int

        enum CodingKeys: String, CodingKey {
            case callInProgress = "call_in_progress"
            case eventQueueFlushInterval = "event_queue_flush_interval"
            case eventQueueFlushSize = "event_queue_flush_size"
            case geoLocation = "geo_location"
            case gyroAccelCadence = "gyro_accel_cadence"
            case gyroAccelCadenceTime = "gyro_accel_cadence_time"
            case requestTimeout = "request_timeout"
        }
    }
    
    var nidConfigCache:Decodable?
    
    // Force fetch optional invoke option allows for retrieving a new config always at invoke, regardless if cache is set
    init(forceFetch: Bool? = false) {
        if (NeuroID.clientKey == nil || NeuroID.clientKey == "") {
            NIDLog.e("Missing Client Key. Config Service not started")
            return
        }
        
        if (nidConfigCache != nil && !forceFetch!) {
            NIDLog.e("NID Config cache has already been set.")
            return
        }
                     
        var config_url = "https://scripts.neuro-id.com/mobile/\(NeuroID.clientKey!)"
        AF.request(config_url, method: .get).responseDecodable(of: ResponseData.self) { response in
            switch response.result {
            case .success(let responseData):
                self.setCache(responseData)
            case .failure(let error):
                NIDLog.e("Failed to retrieve NID Config")
            }
        }
    }
    
    func setCache(_ responseData: Decodable) {
        nidConfigCache = responseData
    }
    
}
