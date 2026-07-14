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

    case developmentURL = "https://receiver.neuro-dev.com/c"

    case storageClientIDKey = "nid_cid"
    case storageTabIDKey = "nid_tid"
    case storageDeviceIDKey = "nid_did"
    case storageDntKey = "nid_dnt"
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
    case lastInstallTime

    // Tags
    case extraInfoTag = "NeuroID Extra:"
    case registrationTag = "NeuroID Registration:"
}

enum UserIDTypes: String {
    case sessionID = "setUserID"  // leaving for log messages
    case registeredUserID = "setRegisteredUserID"
    case attemptedLogin
}

enum SessionOrigin: String {
    case NID_ORIGIN_NID_SET = "nid"
    case NID_ORIGIN_CUSTOMER_SET = "customer"
    case NID_ORIGIN_CODE_FAIL = "400"
    case NID_ORIGIN_CODE_NID = "200"
    case NID_ORIGIN_CODE_CUSTOMER = "201"
}
