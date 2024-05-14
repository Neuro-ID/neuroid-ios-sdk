//
//  NIDConfigService.swift
//  NeuroID

import Alamofire
import Foundation

class NIDConfigService {
    struct ResponseData: Decodable {
        var callInProgress: Bool = true
        var geoLocation: Bool = false
        var eventQueueFlushInterval: Int = 5
        var eventQueueFlushSize: Int = 2000
        var requestTimeout: Int = 10
        var gyroAccelCadence: Bool = false
        var gyroAccelCadenceTime: Int = 200

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
    
    static var cacheSetWithRemote = false
    
    public static var nidConfigCache: ResponseData = .init()
        
    static var nidURL = "https://scripts.neuro-id.com/mobile/"
    
    init(completion: @escaping (Bool) -> Void) {
        if NeuroID.clientKey == nil || NeuroID.clientKey == "" {
            NIDLog.e("Missing Client Key. Config Service not started")
            completion(true)
            return
        }
                     
        let config_url = NIDConfigService.nidURL + NeuroID.clientKey! + ".json"
        AF.request(config_url, method: .get).responseDecodable(of: ResponseData.self) { response in
            switch response.result {
            case .success(let responseData):
                self.setCache(responseData)
                NIDLog.d("Retrieved config log")
                NIDConfigService.cacheSetWithRemote = true
                completion(true)
            case .failure(let error):
                NIDLog.e("Failed to retrieve NID Config \(error)")
                NIDConfigService.nidConfigCache = ResponseData()
                completion(true)
            }
        }
    }
    
    func setCache(_ responseData: ResponseData) {
        NIDConfigService.nidConfigCache = responseData
    }
}
