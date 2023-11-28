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
    case storageClientIdKey = "nid_cid"
    case storageTabIdKey = "nid_tid"
    case storageSiteIdKey = "nid_sid"
    case storageUserIdKey = "nid_user_id"
    case storageDeviceIdKey = "nid_did"
    case storageDntKey = "nid_dnt"
    case storageSessionExpiredKey = "nid_sid_expires"
    case storageSaltKey = "nid_sk"

    case storageAdvancedDeviceKey = "nid_advancedDevice"

    case orientationKey = "orientation"
    case orientationLandscape = "Landscape"
    case orientationPortrait = "Portrait"

    // event item keys
    case eventValuePrefix = "S~C~~"
    case attrKey = "attr"
    case attrScreenHierarchyKey = "screenHierarchy"
    case attrGuidKey = "guid"
    case valueKey = "value"
    case tgsKey = "tgs"
    case etnKey = "etn"
    case etKey = "et"
    case vKey = "v"
    case hashKey = "hash"

    // Tags
    case debugTag = "NeuroID Debug:"
    case integrationHealthTag = "NeuroID IH:"
    case extraInfoTag = "NeuroID Extra:"
    case registrationTag = "NeuroID Registration:"
    case sessionTag = "NeuroID SessionId:"
    case userTag = "NeuroID UserId:"
    case debugTest = "TEST: "
}

internal enum UserIDTypes: String {
    case userID
    case registeredUserID
}
