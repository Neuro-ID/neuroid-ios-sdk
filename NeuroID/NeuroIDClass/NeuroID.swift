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
    internal static let SEND_INTERVAL: Double = 5

    internal static var clientKey: String?
    internal static var siteID: String?

    internal static var clientID: String?
    internal static var userID: String?
    internal static var registeredUserID: String = ""

    internal static var trackers = [String: NeuroIDTracker]()

    /// Turn on/off printing the SDK log to your console
    public static var showLogs = true
    internal static let showDebugLog = false

    internal static var excludedViewsTestIDs = [String]()
    private static let lock = NSLock()

    internal static var environment: String = Constants.environmentTest.rawValue

    fileprivate static var _currentScreenName: String?
    internal static var currentScreenName: String? {
        get { lock.withCriticalSection { _currentScreenName } }
        set { lock.withCriticalSection { _currentScreenName = newValue } }
    }

    internal static var _isSDKStarted: Bool = false
    public static var isSDKStarted: Bool {
        get { _isSDKStarted }
        set {}
    }

    internal static var observingInputs = false
    internal static var observingKeyboard = false
    internal static var didSwizzle: Bool = false

    internal static var verifyIntegrationHealth: Bool = false
    internal static var debugIntegrationHealthEvents: [NIDEvent] = []

    public static var registeredTargets = [String]()

    internal static var isRN: Bool = false
    internal static var rnOptions: [RNConfigOptions: Any] = [:]

    // MARK: - Setup

    /// 1. Configure the SDK
    /// 2. Setup silent running loop
    /// 3. Send cached events from DB every `SEND_INTERVAL`
    public static func configure(clientKey: String) {
        if NeuroID.clientKey != nil {
            NIDLog.e("You already configured the SDK")
        }

        if !validateClientKey(clientKey) {
            NIDLog.e("Invalid Client Key")
            return
        }

        if clientKey.contains("_live_") {
            environment = Constants.environmentLive.rawValue
        } else {
            environment = Constants.environmentTest.rawValue
        }

        // Call clear session here
        clearSession()

        NeuroID.clientKey = clientKey
        setUserDefaultKey(Constants.storageClientKey.rawValue, value: clientKey)

        // Reset tab id on configure
        setUserDefaultKey(Constants.storageTabIDKey.rawValue, value: nil)
    }

    // When start is called, enable swizzling, as well as dispatch queue to send to API
    public static func start() -> Bool {
        if NeuroID.clientKey == nil || NeuroID.clientKey == "" {
            NIDLog.e("Missing Client Key - please call configure prior to calling start")
            return false
        }

        NeuroID._isSDKStarted = true

        NeuroID.startIntegrationHealthCheck()

        NeuroID.createSession()
        swizzle()

        #if DEBUG
        if NSClassFromString("XCTest") == nil {
            initTimer()
        }
        #else
        initTimer()
        #endif

        // save captured health events to file
        saveIntegrationHealthEvents()

        let queuedEvents = DataStore.getAndRemoveAllQueuedEvents()
        queuedEvents.forEach { event in
            DataStore.insertEvent(screen: "", event: event)
        }

        return true
    }

    public static func stop() {
        NIDLog.i("NeuroID Stopped")
        do {
            _ = try closeSession(skipStop: true)
        } catch {
            NIDLog.e("Failed to Stop because \(error)")
        }

        NeuroID.groupAndPOST()
        NeuroID._isSDKStarted = false

        // save captured health events to file
        saveIntegrationHealthEvents()
    }

    public static func isStopped() -> Bool {
        return _isSDKStarted != true
    }

    public static func registerPageTargets() {
        if let viewController = UIApplication.shared.keyWindow?.rootViewController {
            DispatchQueue.main.async {
                viewController.registerPageTargets()
            }
        }
    }

    private static func swizzle() {
        if didSwizzle {
            return
        }

        UIViewController.startSwizzling()
        UITextField.startSwizzling()
        UITextView.startSwizzling()
        UINavigationController.swizzleNavigation()
        UITableView.tableviewSwizzle()
//        UIScrollView.startSwizzlingUIScroll()
//        UIButton.startSwizzling()

        didSwizzle.toggle()
    }

    internal static func saveEventToLocalDataStore(_ event: NIDEvent) {
        DataStore.insertEvent(screen: event.type, event: event)
    }

    internal static func saveQueuedEventToLocalDataStore(_ event: NIDEvent) {
        DataStore.insertQueuedEvent(screen: event.type, event: event)
    }

    /// Get the current SDK versión from bundle
    /// - Returns: String with the version format
    public static func getSDKVersion() -> String {
        return ParamsCreator.getSDKVersion()
    }
}
