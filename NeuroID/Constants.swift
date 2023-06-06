//
//  Constants.swift
//  NeuroID
//
//  Created by Kevin Sites on 4/27/23.
//

import Foundation

internal enum Constants: String {
    case integrationFilePath = "nid"
    case integrationHealthFile = "integrationHealthEvents.json"
    case integrationDeviceInfoFile = "integrationHealthDetails.json"
    case integrationHealthResourceBundle = "Resources"

    case environmentTest = "TEST"
    case environmentLive = "LIVE"

    case debugJsonKey = "debugJSON"
    case debugJsonFileName = "nidJSONPOSTFormat.txt"

    case storageLocalNIDStopAllKey = "nid_stop_all"
    case storageClientKey = "nid_key"
    case storageClientKeyAlt = "nid_cid"
    case storageTabIdKey = "nid_tid"
    case storageSiteIdKey = "nid_sid"
    case storageUserIdKey = "nid_user_id"
    case storageDeviceIdKey = "nid_did"
    case storageDntKey = "nid_dnt"
    case storageSessionExpiredKey = "nid_sid_expires"

    case orientationLandscape = "Landscape"
    case orientationPortrait = "Portrait"

    case eventValuePrefix = "S~C~~"
}
