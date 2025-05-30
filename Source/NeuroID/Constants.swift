//
//  Constants.swift
//  NeuroID
//
//  Created by Kevin Sites on 4/27/23.
//

import Foundation

enum Constants: String {
    case environmentTest = "TEST"
    case environmentLive = "LIVE"

    case productionURL = "https://receiver.neuroid.cloud/c"
    case developmentURL = "https://receiver.neuro-dev.com/c"

    case debugJsonKey = "debugJSON"
    case debugJsonFileName = "nidJSONPOSTFormat.txt"

    case storageLocalNIDStopAllKey = "nid_stop_all"
    case storageClientKey = "nid_key"
    case storageClientIDKey = "nid_cid"
    case storageTabIDKey = "nid_tid"
    case storageDeviceIDKey = "nid_did"
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
    case lastInstallTime = "lastInstallTime"

    // Tags
    case debugTag = "NeuroID Debug:"
    case extraInfoTag = "NeuroID Extra:"
    case registrationTag = "NeuroID Registration:"
    case sessionTag = "NeuroID SessionId:"
    case userTag = "NeuroID UserId:"
    case debugTest = "TEST: "
}

enum UserIDTypes: String {
    case sessionID = "setUserID" // leaving for log messages
    case registeredUserID = "setRegisteredUserID"
    case attemptedLogin = "attemptedLogin"
}

enum SessionOrigin: String {
    case NID_ORIGIN_NID_SET = "nid"
    case NID_ORIGIN_CUSTOMER_SET = "customer"
    case NID_ORIGIN_CODE_FAIL = "400"
    case NID_ORIGIN_CODE_NID = "200"
    case NID_ORIGIN_CODE_CUSTOMER = "201"
}

enum CallInProgress: String {
    case ACTIVE = "true"
    case INACTIVE = "false"
    case UNAUTHORIZED = "unauthorized"
}

enum CallInProgressMetaData: String {
    case OUTGOING = "outgoing"
    case INCOMING = "incoming"
    case ANSWERED = "answered"
    case ENDED = "ended"
    case ONHOLD = "onhold"
    case RINGING = "ringing"
}
