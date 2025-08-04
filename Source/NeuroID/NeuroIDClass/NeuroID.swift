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

public class NeuroID: NSObject {
    static let SEND_INTERVAL: Double = 5

    static var advancedDeviceKey: String? = nil
    static var clientKey: String?
    static var siteID: String?
    static var linkedSiteID: String?

    static var logger: NIDLog = .init()
    static var datastore: DataStoreProtocol = DataStore(logger: logger)
    static var eventStorageService: EventStorageService = .init()
    static var validationService: ValidationService = .init(logger: logger)
    static var locationManager: LocationManagerService?
    static var networkMonitor: NetworkMonitoringService?
    static var callObserver: NIDCallStatusObserverService?
    static var configService: ConfigServiceProtocol = NIDConfigService(logger: logger)
    static var identifierService: IdentifierServiceProtocol = IdentifierService(
        logger: logger,
        validationService: NeuroID.validationService,
        eventStorageService: NeuroID.eventStorageService
    )
    static var networkService: NIDNetworkServiceProtocol = NIDNetworkServiceImpl(logger: logger)

    static var clientID: String?
    static var sessionID: String? {
        get {
            identifierService.sessionID
        }
        set {
            // setting should not be possible unless through our setIdentity/setUserId command
        }
    } // Formerly known as userID, now within the mobile sdk ONLY sessionID
    static var registeredUserID: String {
        get {
            identifierService.registeredUserID
        }
        set {
            // setting should not be possible unless through our setRegisteredUserId command
        }
    }

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

    static var sendCollectionWorkItem: DispatchWorkItem?
    static var sendGyroAccelCollectionWorkItem: DispatchWorkItem?

    static var observingInputs = false
    static var observingKeyboard = false
    static var didSwizzle: Bool = false

    public static var registeredTargets = [String]()

    static var isRN: Bool = false
    static var rnOptions: [RNConfigOptions: Any] = [:]

    static var lowMemory: Bool = false

    static var isAdvancedDevice: Bool = false

    static var packetNumber: Int32 = 0

    // Testing Purposes Only
    static var _isTesting = false

    // MARK: - Setup

    static func verifyClientKeyExists() -> Bool {
        if NeuroID.clientKey == nil || NeuroID.clientKey == "" {
            logger.e("Missing Client Key - please call configure prior to calling start")
            return false
        }
        return true
    }

    /// 1. Configure the SDK
    /// 2. Setup silent running loop
    /// 3. Send cached events from DB every `SEND_INTERVAL`
    public static func configure(clientKey: String, isAdvancedDevice: Bool = false, advancedDeviceKey: String? = nil) -> Bool {
        // set last install time if not already set.
        if getUserDefaultKeyDouble(Constants.lastInstallTime.rawValue) == 0 {
            setUserDefaultKey(Constants.lastInstallTime.rawValue, value: Date().timeIntervalSince1970)
        }

        if NeuroID.clientKey != nil {
            logger.e("You already configured the SDK")
            return false
        }

        if !validationService.validateClientKey(clientKey) {
            logger.e("Invalid Client Key")
            saveQueuedEventToLocalDataStore(
                NIDEvent(
                    type: NIDEventName.log,
                    level: "ERROR",
                    m: "Invalid Client Key \(clientKey)"
                )
            )
            setUserDefaultKey(Constants.storageTabIDKey.rawValue, value: ParamsCreator.getTabId() + "-invalid-client-key")

            return false
        }
        NeuroID.advancedDeviceKey = advancedDeviceKey
        NeuroID.isAdvancedDevice = isAdvancedDevice

        if clientKey.contains("_live_") {
            environment = Constants.environmentLive.rawValue
        } else {
            environment = Constants.environmentTest.rawValue
        }

        NeuroID.clearSessionVariables()

        NeuroID.clientKey = clientKey
        setUserDefaultKey(Constants.storageClientKey.rawValue, value: clientKey)

        // Reset tab id / packet number on configure
        setUserDefaultKey(Constants.storageTabIDKey.rawValue, value: nil)
        saveEventToDataStore(NIDEvent(type: NIDEventName.log, level: "INFO", m: "Reset Tab Id"))
        packetNumber = 0

        networkMonitor = NetworkMonitoringService()
        networkMonitor?.startMonitoring()

        if isAdvancedDevice {
            captureAdvancedDevice()
        }

        captureApplicationMetaData()

        NeuroID.saveEventToDataStore(
            NIDEvent(type: .log, level: "INFO", m: "isAdvancedDevice setting: \(isAdvancedDevice)")
        )

        return true
    }

    static func configSetupCompletion() {
        saveEventToLocalDataStore(
            NIDEvent(type: .log, level: "info", m: "Remote Config Retrieval Attempt Completed")
        )
        logger.i("Remote Config Retrieval Attempt Completed")

        setupListeners()
    }

    // When start is called, enable swizzling, as well as dispatch queue to send to API
    public static func start(
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        NeuroID.start(siteID: nil, completion: completion)
    }

    public static func stop() -> Bool {
        logger.i("NeuroID Stopped")
        do {
            _ = try closeSession(skipStop: true)
        } catch {
            logger.e("Failed to Stop because \(error)")
            let stopFailedLogEvent = NIDEvent(type: NIDEventName.log, level: "ERROR", m: "Failed to Stop because \(error)")
            saveEventToDataStore(stopFailedLogEvent)
            return false
        }

        NeuroID.groupAndPOST(forceSend: true)
        NeuroID._isSDKStarted = false
        NeuroID.linkedSiteID = nil

        //  stop listening to changes in call status
        NeuroID.callObserver?.stopListeningToCallStatus()
        return true
    }

    public static func isStopped() -> Bool {
        return _isSDKStarted != true
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

    /// Get the current SDK versión from bundle
    /// - Returns: String with the version format
    public static func getSDKVersion() -> String {
        return ParamsCreator.getSDKVersion()
    }

    static func captureApplicationMetaData() {
        let appMetaData = getAppMetaData()

        let event = NIDEvent(type: .applicationMetaData)
        event.attrs = [
            Attrs(n: "versionName", v: appMetaData?.versionName ?? "N/A"),
            Attrs(n: "versionNumber", v: appMetaData?.versionNumber ?? "N/A"),
            Attrs(n: "packageName", v: appMetaData?.packageName ?? "N/A"),
            Attrs(n: "applicationName", v: appMetaData?.applicationName ?? "N/A"),
        ]

        saveEventToDataStore(event)
    }

    static func getAppMetaData() -> ApplicationMetaData? {
        let bundleID: String
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            bundleID = bundleIdentifier
        } else {
            bundleID = ""
        }

        if let infoDictionary = Bundle.main.infoDictionary {
            let packageName = infoDictionary["CFBundleName"] as? String ?? "Unknown"
            let versionName = infoDictionary["CFBundleShortVersionString"] as? String ?? "Unknown"
            let versionNumber = infoDictionary["CFBundleVersion"] as? String ?? "Unknown"

            return ApplicationMetaData(
                versionName: versionName,
                versionNumber: versionNumber,
                packageName: bundleID.isEmpty ? packageName : bundleID,
                applicationName: packageName
            )
        }
        return nil
    }

    // ENG-9193 - Will remove on next breaking release
    @available(*, deprecated, message: "printIntegrationHealthInstruction is deprecated and no longer functional")
    public static func printIntegrationHealthInstruction() {
        logger.i("**** NOTE: THIS METHOD IS DEPRECATED AND IS NO LONGER FUNCTIONAL")
    }

    // ENG-9193 - Will remove on next breaking release
    @available(*, deprecated, message: "printIntegrationHealthInstruction is deprecated and no longer functional")
    public static func setVerifyIntegrationHealth(_ verify: Bool) {
        logger.i("**** NOTE: THIS METHOD IS DEPRECATED AND IS NO LONGER FUNCTIONAL")
    }
}
