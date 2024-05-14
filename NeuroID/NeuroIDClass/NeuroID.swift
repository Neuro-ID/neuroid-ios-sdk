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

public class NeuroID: NSObject {
    static let SEND_INTERVAL: Double = 5
    static var CURRENT_ORIGIN: String?
    static var CURRENT_ORIGIN_CODE: String?

    static var clientKey: String?
    static var siteID: String?
    static var linkedSiteID: String?

    static var locationManager: LocationManager?
    static var networkMonitor: NetworkMonitoringService?
    static var callObserver: NIDCallStatusObserver?
    static var configService: NIDConfigService = .init()

    static var clientID: String?
    static var userID: String?
    static var registeredUserID: String = ""

    static var trackers = [String: NeuroIDTracker]()

    /// Turn on/off printing the SDK log to your console
    public static var showLogs = true
    static let showDebugLog = false

    static var excludedViewsTestIDs = [String]()
    private static let lock = NSLock()

    static var environment: String = Constants.environmentTest.rawValue

    fileprivate static var _currentScreenName: String?
    static var currentScreenName: String? {
        get { lock.withCriticalSection { _currentScreenName } }
        set { lock.withCriticalSection { _currentScreenName = newValue } }
    }

    static var _isSDKStarted: Bool = false
    public static var isSDKStarted: Bool {
        get { _isSDKStarted }
        set {}
    }

    static var _isSessionSampled: Bool = true

    static var sendCollectionWorkItem: DispatchWorkItem?
    static var sendGyroAccelCollectionWorkItem: DispatchWorkItem?

    static var observingInputs = false
    static var observingKeyboard = false
    static var didSwizzle: Bool = false

    static var verifyIntegrationHealth: Bool = false
    static var debugIntegrationHealthEvents: [NIDEvent] = []

    public static var registeredTargets = [String]()

    static var isRN: Bool = false
    static var rnOptions: [RNConfigOptions: Any] = [:]

    static var lowMemory: Bool = false

    static var isAdvancedDevice: Bool = false

    // MARK: - Setup

    static func verifyClientKeyExists() -> Bool {
        if NeuroID.clientKey == nil || NeuroID.clientKey == "" {
            NIDLog.e("Missing Client Key - please call configure prior to calling start")
            return false
        }
        return true
    }

    /// 1. Configure the SDK
    /// 2. Setup silent running loop
    /// 3. Send cached events from DB every `SEND_INTERVAL`
    public static func configure(clientKey: String, isAdvancedDevice: Bool = false) -> Bool {
        if NeuroID.clientKey != nil {
            NIDLog.e("You already configured the SDK")
            return false
        }

        if !validateClientKey(clientKey) {
            NIDLog.e("Invalid Client Key")
            return false
        }

        NeuroID.isAdvancedDevice = isAdvancedDevice

        if clientKey.contains("_live_") {
            environment = Constants.environmentLive.rawValue
        } else {
            environment = Constants.environmentTest.rawValue
        }

        clearStoredSessionID()
        NeuroID.linkedSiteID = nil

        NeuroID.clientKey = clientKey
        setUserDefaultKey(Constants.storageClientKey.rawValue, value: clientKey)

        // Reset tab id on configure
        setUserDefaultKey(Constants.storageTabIDKey.rawValue, value: nil)

        networkMonitor = NetworkMonitoringService()
        networkMonitor?.startMonitoring()

        return true
    }

    // When start is called, enable swizzling, as well as dispatch queue to send to API
    public static func start(
        completion: @escaping (Bool) -> Void = { _ in }
    ) -> Bool {
        if !NeuroID.verifyClientKeyExists() {
            completion(false)

            // this is now inaccurate but keeping for backwards compatibility
            return false
        }

        // Use config cache or if first time, retrieve from server
        configService.updateConfigOptions {
            // Setup Session with old start timer logic
            // TO-DO - Refactor to behave like startSession
            NeuroID.setupSession {
                #if DEBUG
                if NSClassFromString("XCTest") == nil {
                    initTimer()
                }
                #else
                initTimer()
                #endif
                initGyroAccelCollectionTimer()
            }

            completion(true)
        }

        // this is now inaccurate but keeping for backwards compatibility
        return true
    }

    public static func stop() -> Bool {
        NIDLog.i("NeuroID Stopped")
        do {
            _ = try closeSession(skipStop: true)
        } catch {
            NIDLog.e("Failed to Stop because \(error)")
            return false
        }

        NeuroID.groupAndPOST(forceSend: true)
        NeuroID._isSDKStarted = false
        NeuroID.linkedSiteID = nil

        // save captured health events to file
        saveIntegrationHealthEvents()

        //  stop listening to changes in call status
        NeuroID.callObserver?.stopListeningToCallStatus()
        return true
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

    static func checkThenCaptureAdvancedDevice(_ shouldCapture: Bool = NeuroID.isAdvancedDevice) {
        let selectorString = "captureAdvancedDevice:"
        let selector = NSSelectorFromString(selectorString)

        // Check if the runtime environemnt has adv libs installed
        if NeuroID.responds(to: selector) {
            NeuroID.perform(selector, with: [shouldCapture])
        } else {
            NIDLog.d("No advanced library found")
        }
    }

    static func swizzle() {
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

    static func saveEventToLocalDataStore(_ event: NIDEvent) {
        DataStore.insertEvent(screen: event.type, event: event)
    }

    static func saveQueuedEventToLocalDataStore(_ event: NIDEvent) {
        DataStore.insertQueuedEvent(screen: event.type, event: event)
    }

    /// Get the current SDK versión from bundle
    /// - Returns: String with the version format
    public static func getSDKVersion() -> String {
        return ParamsCreator.getSDKVersion()
    }
}
