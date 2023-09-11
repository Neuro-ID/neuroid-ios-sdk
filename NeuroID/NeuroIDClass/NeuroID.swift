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
    internal static var siteId: String?

    internal static var clientId: String?
    internal static var userId: String?

    internal static var trackers = [String: NeuroIDTracker]()

    /// Turn on/off printing the SDK log to your console
    public static var logVisible = true
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
        setUserDefaultKey(Constants.storageClientKey.rawValue, value: clientKey)

        // Reset tab id on configure
        setUserDefaultKey(Constants.storageTabIdKey.rawValue, value: nil)
    }

    // When start is called, enable swizzling, as well as dispatch queue to send to API
    public static func start() {
        NeuroID._isSDKStarted = true
        setUserDefaultKey(Constants.storageLocalNIDStopAllKey.rawValue, value: false)

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
    }

    public static func stop() {
        NIDPrintLog("NeuroID Stopped")
        setUserDefaultKey(Constants.storageLocalNIDStopAllKey.rawValue, value: true)
        do {
            _ = try closeSession(skipStop: true)
        } catch {
            NIDPrintLog("NeuroID Error: Failed to Stop because \(error)")
        }

        NeuroID._isSDKStarted = false

        // save captured health events to file
        saveIntegrationHealthEvents()
    }

    public static func isStopped() -> Bool {
        return getUserDefaultKeyBool(Constants.storageLocalNIDStopAllKey.rawValue)
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

    public static func saveEventToLocalDataStore(_ event: NIDEvent) {
        DataStore.insertEvent(screen: event.type, event: event)
    }

    /// Get the current SDK versión from bundle
    /// - Returns: String with the version format
    static func getSDKVersion() -> String? {
        return ParamsCreator.getSDKVersion()
    }
}
