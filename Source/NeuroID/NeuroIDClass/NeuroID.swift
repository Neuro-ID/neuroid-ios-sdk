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
    static let shared: NeuroID = .init()

    var advancedDeviceKey: String? = nil
    var clientKey: String?
    var siteID: String?
    var linkedSiteID: String?

    // Services
    var logger: LoggerProtocol
    var datastore: DataStoreServiceProtocol
    var eventStorageService: EventStorageServiceProtocol
    var validationService: ValidationServiceProtocol
    var configService: ConfigServiceProtocol
    var identifierService: IdentifierServiceProtocol
    var networkService: NetworkServiceProtocol
    var networkMonitor: NetworkMonitoringServiceProtocol
    var deviceSignalService: AdvancedDeviceServiceProtocol
    var payloadSendingService: PayloadSendingServiceProtocol

    var callObserver: CallStatusObserverServiceProtocol?
    var locationManager: LocationManagerServiceProtocol?

    // flag to ensure that we only have one FPJS call in flight
    var isFPJSRunning = false

    var clientID: String?
    static var sessionID: String? {
        get {
            NeuroID.shared.identifierService.sessionID
        }
        set {
            // setting should not be possible unless through our setIdentity/setUserId command
        }
    } // Formerly known as userID, now within the mobile sdk ONLY sessionID
    static var registeredUserID: String {
        get {
            NeuroID.shared.identifierService.registeredUserID
        }
        set {
            // setting should not be possible unless through our setRegisteredUserId command
        }
    }

    static var trackers = [String: NeuroIDTracker]()

    /// Turn on/off printing the SDK log to your console
    public static var showLogs = true
    let showDebugLog = false

    static var excludedViewsTestIDs = [String]()
    private static let lock = NSLock()

    static var environment: String = Constants.environmentTest.rawValue

    fileprivate static var _currentScreenName: String?
    static var currentScreenName: String? {
        get { lock.withCriticalSection { _currentScreenName } }
        set { lock.withCriticalSection { _currentScreenName = newValue } }
    }

    var _isSDKStarted: Bool = false
    public static var isSDKStarted: Bool { NeuroID.shared._isSDKStarted }

    // Defining Collection and Gyro Tasks here because the job is recreated for new interval timing in the setupListeners fn.
    static var sendCollectionEventsTask: () -> Void = {
        NeuroID.send()
    }

    static var collectGyroAccelEventTask: () -> Void = {
        if !NeuroID.isStopped(), NeuroID.shared.configService.configCache.gyroAccelCadence {
            NeuroID.saveEventToLocalDataStore(
                NIDEvent(
                    type: .cadenceReadingAccel,
                    attrs: [
                        Attrs(
                            n: "interval",
                            v: "\(NeuroID.shared.configService.configCache.gyroAccelCadenceTime)ms"
                        ),
                    ]
                )
            )
        }
    }

    static var sendCollectionEventsJob: RepeatingTaskProtocol = RepeatingTask(
        interval: Double(5), // default 5, will be recreated on `configure` command
        task: NeuroID.sendCollectionEventsTask
    )

    static var sendGyroAccelCollectionWorkItem: RepeatingTaskProtocol = RepeatingTask(
        interval: Double(5), // default 5, will be recreated on `configure` command
        task: NeuroID.collectGyroAccelEventTask
    )

    static var observingInputs = false
    static var observingKeyboard = false
    static var didSwizzle: Bool = false

    public static var registeredTargets = [String]()

    var isRN: Bool = false
    var rnOptions: [RNConfigOptions: Any] = [:]

    static var lowMemory: Bool = false

    static var isAdvancedDevice: Bool = false

    var packetNumber: Int32 = 0

    // Testing Purposes Only
    static var _isTesting = false

    // MARK: - Setup

    init(
        logger: LoggerProtocol? = nil,
        datastore: DataStoreServiceProtocol? = nil,
        eventStorageService: EventStorageServiceProtocol? = nil,
        validationService: ValidationServiceProtocol? = nil,
        networkService: NetworkServiceProtocol? = nil,
        configService: ConfigServiceProtocol? = nil,
        identifierService: IdentifierServiceProtocol? = nil,
        networkMonitor: NetworkMonitoringServiceProtocol? = nil,
        deviceSignalService: AdvancedDeviceServiceProtocol? = nil,
        payloadSendingService: PayloadSendingServiceProtocol? = nil,
        callObserver: CallStatusObserverServiceProtocol? = nil,
        locationManager: LocationManagerServiceProtocol? = nil
    ) {
        self.logger = logger ?? NIDLog()
        self.datastore = datastore ?? DataStore(logger: self.logger)
        self.eventStorageService = eventStorageService ?? EventStorageService()
        self.validationService = validationService ?? ValidationService(logger: self.logger)
        self.networkService = networkService ?? NIDNetworkServiceImpl(logger: self.logger)
        self.configService =
            configService
                ?? NIDConfigService(
                    logger: self.logger,
                    networkService: self.networkService,
                    configRetrievalCallback: NeuroID.configSetupCompletion
                )
        self.identifierService =
            identifierService
                ?? IdentifierService(
                    logger: self.logger,
                    validationService: self.validationService,
                    eventStorageService: self.eventStorageService
                )
        self.networkMonitor = networkMonitor ?? NetworkMonitoringService()
        self.deviceSignalService = deviceSignalService ?? AdvancedDeviceService()
        self.payloadSendingService =
            payloadSendingService
                ?? PayloadSendingService(
                    logger: self.logger,
                    datastore: self.datastore,
                    networkService: self.networkService
                )
        self.callObserver = callObserver
        self.locationManager = locationManager

        NeuroID.sendCollectionEventsJob = RepeatingTask(
            interval: Double(self.configService.configCache.eventQueueFlushInterval),
            task: NeuroID.sendCollectionEventsTask
        )

        NeuroID.sendGyroAccelCollectionWorkItem = RepeatingTask(
            interval: Double(self.configService.configCache.gyroAccelCadenceTime),
            task: NeuroID.collectGyroAccelEventTask
        )
    }

    static func verifyClientKeyExists() -> Bool {
        if NeuroID.shared.clientKey == nil || NeuroID.shared.clientKey == "" {
            NeuroID.shared.logger.e("Missing Client Key - please call configure prior to calling start")
            return false
        }
        return true
    }

    /// 1. Configure the SDK
    /// 2. Setup silent running loop
    /// 3. Send cached events from DB every `SEND_INTERVAL`
    public static func configure(
        clientKey: String, isAdvancedDevice: Bool = false, advancedDeviceKey: String? = nil
    ) -> Bool {
        // set last install time if not already set.
        if getUserDefaultKeyDouble(Constants.lastInstallTime.rawValue) == 0 {
            setUserDefaultKey(Constants.lastInstallTime.rawValue, value: Date().timeIntervalSince1970)
        }

        if NeuroID.verifyClientKeyExists() {
            NeuroID.shared.logger.e("You already configured the SDK")
            return false
        }

        if !NeuroID.shared.validationService.validateClientKey(clientKey) {
            NeuroID.shared.logger.e("Invalid Client Key")
            saveQueuedEventToLocalDataStore(
                NIDEvent.createErrorLogEvent(
                    "Invalid Client Key \(clientKey)"
                )
            )
            setUserDefaultKey(
                Constants.storageTabIDKey.rawValue, value: ParamsCreator.getTabId() + "-invalid-client-key"
            )

            return false
        }
        NeuroID.shared.advancedDeviceKey = advancedDeviceKey
        NeuroID.isAdvancedDevice = isAdvancedDevice

        if clientKey.contains("_live_") {
            environment = Constants.environmentLive.rawValue
        } else {
            environment = Constants.environmentTest.rawValue
        }

        NeuroID.clearSessionVariables()

        NeuroID.shared.clientKey = clientKey
        setUserDefaultKey(Constants.storageClientKey.rawValue, value: clientKey)

        // Reset tab id / packet number on configure
        setUserDefaultKey(Constants.storageTabIDKey.rawValue, value: nil)
        saveEventToDataStore(
            NIDEvent.createInfoLogEvent("Reset Tab Id")
        )
        NeuroID.shared.packetNumber = 0

        NeuroID.shared.networkMonitor.startMonitoring()

        if isAdvancedDevice {
            captureAdvancedDevice()
        }

        captureApplicationMetaData()

        NeuroID.saveEventToDataStore(
            NIDEvent.createInfoLogEvent("isAdvancedDevice setting: \(isAdvancedDevice)")
        )

        return true
    }

    static func configSetupCompletion() {
        saveEventToLocalDataStore(
            NIDEvent.createInfoLogEvent("Remote Config Retrieval Attempt Completed")
        )
        NeuroID.shared.logger.i("Remote Config Retrieval Attempt Completed")

        setupListeners()
    }

    // When start is called, enable swizzling, as well as dispatch queue to send to API
    public static func start(
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        NeuroID.start(siteID: nil, completion: completion)
    }

    public static func stop() -> Bool {
        NeuroID.shared.logger.i("NeuroID Stopped")
        do {
            _ = try closeSession(skipStop: true)
        } catch {
            NeuroID.shared.logger.e("Failed to Stop because \(error)")
            saveEventToDataStore(
                NIDEvent.createErrorLogEvent("Failed to Stop because \(error)")
            )
            return false
        }

        NeuroID.send(forceSend: true)
        NeuroID.shared._isSDKStarted = false
        NeuroID.shared.linkedSiteID = nil

        //  stop listening to changes in call status
        NeuroID.shared.callObserver?.stopListeningToCallStatus()
        return true
    }

    public static func isStopped() -> Bool {
        return NeuroID.shared._isSDKStarted != true
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
        // UIScrollView.startSwizzlingUIScroll()
        // UIButton.startSwizzling()

        didSwizzle.toggle()
    }

    /// Get the current SDK versión from bundle
    /// - Returns: String with the version format
    public static func getSDKVersion() -> String {
        return ParamsCreator.getSDKVersion()
    }

    static func captureApplicationMetaData() {
        let appMetaData = getAppMetaData()

        saveEventToDataStore(
            NIDEvent(
                type: .applicationMetaData,
                attrs: [
                    Attrs(n: "versionName", v: appMetaData?.versionName ?? "N/A"),
                    Attrs(n: "versionNumber", v: appMetaData?.versionNumber ?? "N/A"),
                    Attrs(n: "packageName", v: appMetaData?.packageName ?? "N/A"),
                    Attrs(n: "applicationName", v: appMetaData?.applicationName ?? "N/A"),
                ]
            )
        )
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
    @available(
        *, deprecated,
        message: "printIntegrationHealthInstruction is deprecated and no longer functional"
    )
    public static func printIntegrationHealthInstruction() {
        NeuroID.shared.logger.i("**** NOTE: THIS METHOD IS DEPRECATED AND IS NO LONGER FUNCTIONAL")
    }

    // ENG-9193 - Will remove on next breaking release
    @available(
        *, deprecated,
        message: "printIntegrationHealthInstruction is deprecated and no longer functional"
    )
    public static func setVerifyIntegrationHealth(_ verify: Bool) {
        NeuroID.shared.logger.i("**** NOTE: THIS METHOD IS DEPRECATED AND IS NO LONGER FUNCTIONAL")
    }
}
