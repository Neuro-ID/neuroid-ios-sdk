//
//  ConfigModels.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/10/24.
//

import Foundation

struct LinkedSiteOption: Decodable {
    var sampleRate: Double

    enum CodingKeys: String, CodingKey {
        case sampleRate = "sample_rate"
    }
}

struct ConfigResponseData: Decodable {
    var callInProgress: Bool = true
    var geoLocation: Bool = true
    var eventQueueFlushInterval: Int = 5
    var eventQueueFlushSize: Int = 2000
    var requestTimeout: Int = 10
    var gyroAccelCadence: Bool = false
    var gyroAccelCadenceTime: Int = 200

    // could exist for parent site or could be null meaning 100%
    var sampleRate: Double? = NIDConfigService.DEFAULT_SAMPLE_RATE

    // this is where we store the variable to be used. If updateConfigOptions is called then this value will be overritten to use the latest version
    var currentSampleRate: Double = 100
    var siteID: String? = "" // should not be optional but older configs might not have it
    var linkedSiteOptions: [String: LinkedSiteOption]? = [:]

    enum CodingKeys: String, CodingKey {
        case callInProgress = "call_in_progress"
        case eventQueueFlushInterval = "event_queue_flush_interval"
        case eventQueueFlushSize = "event_queue_flush_size"
        case geoLocation = "geo_location"
        case gyroAccelCadence = "gyro_accel_cadence"
        case gyroAccelCadenceTime = "gyro_accel_cadence_time"
        case requestTimeout = "request_timeout"
        case sampleRate = "sample_rate"
        case siteID = "site_id"
        case linkedSiteOptions = "linked_site_options"
    }
}
