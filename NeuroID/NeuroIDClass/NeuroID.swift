//
//  NeuroID.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Alamofire
import CommonCrypto
import Foundation
import ObjectiveC
import os
import SwiftUI
import UIKit
import WebKit

// MARK: - Neuro ID Class

public enum NeuroID {
    fileprivate static var sequenceId = 1
    internal static var clientKey: String?
    internal static var siteId: String?
    fileprivate static let sessionId: String = ParamsCreator.getSessionID()
    public static var clientId: String?
    public static var userId: String?
    public static var registeredTargets = [String]()
    internal static let SEND_INTERVAL: Double = 5
    internal static var trackers = [String: NeuroIDTracker]()
    internal static var secretViews = [UIView]()
    internal static let showDebugLog = false
    fileprivate static var _currentScreenName: String?

    static var excludedViewsTestIDs = [String]()
    private static let lock = NSLock()

    internal static var environment: String = Constants.environmentTest.rawValue
    internal static var currentScreenName: String? {
        get { lock.withCriticalSection { _currentScreenName } }
        set { lock.withCriticalSection { _currentScreenName = newValue } }
    }

    fileprivate static let localStorageNIDStopAll = Constants.storageLocalNIDStopAllKey.rawValue

    /// Turn on/off printing the SDK log to your console
    public static var logVisible = true
    public static var activeView: UIView?
    public static var collectorURLFromConfig: String?
    public static var isSDKStarted = false
    public static var observingInputs = false
    internal static var observingKeyboard = false

    internal static var verifyIntegrationHealth: Bool = false
    internal static var debugIntegrationHealthEvents: [NIDEvent] = []

    // MARK: - Setup

    /// 1. Configure the SDK
    /// 2. Setup silent running loop
    /// 3. Send cached events from DB every `SEND_INTERVAL`
    public static func configure(clientKey: String) {
        if NeuroID.clientKey != nil {
            print("NeuroID Error: You already configured the SDK")
        }

        // Call clear session here
        clearSession()

        NeuroID.clientKey = clientKey
        let key = Constants.storageClientKey.rawValue
        let defaults = UserDefaults.standard
        defaults.set(clientKey, forKey: key)

        // Reset tab id on configure
        UserDefaults.standard.set(nil, forKey: Constants.storageTabIdKey.rawValue)
    }

    // Allow for configuring of collector endpoint (useful for testing before MSA is signed)
    public static func configure(clientKey: String, collectorEndPoint: String) {
        collectorURLFromConfig = collectorEndPoint
        configure(clientKey: clientKey)
    }

    // When start is called, enable swizzling, as well as dispatch queue to send to API
    public static func start() {
        NeuroID.isSDKStarted = true
        UserDefaults.standard.set(false, forKey: localStorageNIDStopAll)

        NeuroID.startIntegrationHealthCheck()

        NeuroID.createSession()
        swizzle()

        if ProcessInfo.processInfo.environment[Constants.debugJsonKey.rawValue] == "true" {
            let filemgr = FileManager.default
            let path = filemgr.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(Constants.debugJsonFileName.rawValue)
            NIDPrintLog("DEBUG PATH \(path.absoluteString)")
        }

        #if DEBUG
        if NSClassFromString("XCTest") == nil {
            initTimer()
        }
        #else
        initTimer()
        #endif

        // save captured health events to file
        saveIntegrationHealthEvents()
    }

    public static func stop() {
        NIDPrintLog("NeuroID Stopped")
        UserDefaults.standard.set(true, forKey: localStorageNIDStopAll)

        do {
            try closeSession(skipStop: true)
        } catch {
            NIDPrintLog("Failed to Stop because: \(error)")
        }

        // save captured health events to file
        saveIntegrationHealthEvents()
    }

    public static func isStopped() -> Bool {
        let key = UserDefaults.standard.bool(forKey: localStorageNIDStopAll)
        if key {
            return true
        }
        return false
    }

    private static func swizzle() {
        UIViewController.startSwizzling()
        UITextField.startSwizzling()
        UITextView.startSwizzling()
        UINavigationController.swizzleNavigation()
        UITableView.tableviewSwizzle()
//        UIButton.startSwizzling()
    }

    public static func saveEventToLocalDataStore(_ event: NIDEvent) {
        DataStore.insertEvent(screen: event.type, event: event)
    }
}

// MARK: - NeuroID for testing functions

public extension NeuroID {
    internal static func cleanUpForTesting() {
        clientKey = nil
    }

    /// Get the current SDK versión from bundle
    /// - Returns: String with the version format
    static func getSDKVersion() -> String? {
        return ParamsCreator.getSDKVersion()
    }
}
