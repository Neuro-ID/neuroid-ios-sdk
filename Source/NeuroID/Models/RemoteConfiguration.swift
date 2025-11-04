//
//  RemoteConfiguration.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/10/24.
//

import Foundation

struct RemoteConfiguration: Codable {
    var callInProgress: Bool = true
    var geoLocation: Bool = false
    var eventQueueFlushInterval: Int = 5
    var eventQueueFlushSize: Int = 2000
    var requestTimeout: Int = 10
    var gyroAccelCadence: Bool = false
    var gyroAccelCadenceTime: Int = 200
    var lowMemoryBackOff: Double? = NIDConfigService.DEFAULT_LOW_MEMORY_BACK_OFF
    var advancedCookieExpiration: Int? = NIDConfigService.DEFAULT_ADV_COOKIE_EXPIRATION

    // could exist for parent site or could be null meaning 100%
    var sampleRate: Int? = NIDConfigService.DEFAULT_SAMPLE_RATE

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
        case lowMemoryBackOff = "low_memory_back_off"
        case advancedCookieExpiration = "advanced_cookie_expires"
    }
}

struct LinkedSiteOption: Codable {
    var sampleRate: Int? = NIDConfigService.DEFAULT_SAMPLE_RATE

    enum CodingKeys: String, CodingKey {
        case sampleRate = "sample_rate"
    }
}
