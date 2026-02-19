//
//  NeuroID.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import UIKit

public class NeuroIDCore: NSObject {
    static let nidVersion = "3.6.0"
    static let shared: NeuroIDCore = NeuroIDCore()

    // Configuration
    var clientKey: String?
    var isAdvancedDevice: Bool = false
    var advancedDeviceKey: String? = nil
    var useAdvancedDeviceProxy: Bool = false

    var siteID: String?
    var linkedSiteID: String?

    // Services
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
    var sessionID: String? {
        // Formerly known as userID, now within the mobile sdk ONLY sessionID
        // setting should only be through our setIdentity/setUserId command
        self.identifierService.sessionID
    }

    var registeredUserID: String {
        // setting should only be through our setRegisteredUserId command
        self.identifierService.registeredUserID
    }

    static var trackers = [String: NeuroIDTracker]()

    /// Turn on/off printing the SDK log to your console
    var showLogs = true

    var excludedViewsTestIDs = [String]()
    private static let lock = NSLock()

    var environment: String = Constants.environmentTest.rawValue

    var _currentScreenName: String?

    var _isSDKStarted: Bool = false
    public var isSDKStarted: Bool { self._isSDKStarted }

    // Defining Collection and Gyro Tasks here because the job is recreated for new interval timing in the setupListeners fn.
    static var sendCollectionEventsTask: () -> Void = {
        NeuroIDCore.shared.send()
    }

    static var collectGyroAccelEventTask: () -> Void = {
        if !NeuroIDCore.isStopped(), NeuroIDCore.shared.configService.configCache.gyroAccelCadence {
            NeuroIDCore.shared.saveEventToLocalDataStore(
                NIDEvent(
                    type: .cadenceReadingAccel,
                    attrs: [
                        Attrs(
                            n: "interval",
                            v: "\(NeuroIDCore.shared.configService.configCache.gyroAccelCadenceTime)ms"
                        ),
                    ]
                )
            )
        }
    }

    var sendCollectionEventsJob: RepeatingTaskProtocol = RepeatingTask(
        interval: Double(5), // default 5, will be recreated on `configure` command
        task: NeuroIDCore.sendCollectionEventsTask
    )

    var collectGyroAccelEventJob: RepeatingTaskProtocol = RepeatingTask(
        interval: Double(5), // default 5, will be recreated on `configure` command
        task: NeuroIDCore.collectGyroAccelEventTask
    )

    var observingInputs = false
    var observingKeyboard = false
    var didSwizzle: Bool = false

    public static var registeredTargets = [String]()

    var isRN: Bool = false
    var rnOptions: [RNConfigOptions: Any] = [:]

    var lowMemory: Bool = false

    var packetNumber: Int32 = 0

    // Testing Purposes Only
    static var _isTesting = false

    // MARK: - Setup

    init(
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
        self.datastore = datastore ?? DataStore()
        self.eventStorageService = eventStorageService ?? EventStorageService()
        self.validationService = validationService ?? ValidationService()
        self.networkService = networkService ?? NetworkService()
        self.configService =
            configService
            ?? ConfigService(
                networkService: self.networkService,
                configRetrievalCallback: {}  // callback is reconfigured on `configure` command
            )
        self.identifierService =
            identifierService
            ?? IdentifierService(
                validationService: self.validationService,
                eventStorageService: self.eventStorageService
            )
        self.networkMonitor = networkMonitor ?? NetworkMonitoringService()
        self.deviceSignalService = deviceSignalService ?? AdvancedDeviceService()
        self.payloadSendingService =
            payloadSendingService
            ?? PayloadSendingService(
                datastore: self.datastore,
                networkService: self.networkService
            )
        self.callObserver = callObserver
        self.locationManager = locationManager

        self.sendCollectionEventsJob = RepeatingTask(
            interval: Double(self.configService.configCache.eventQueueFlushInterval),
            task: NeuroIDCore.sendCollectionEventsTask
        )

        self.collectGyroAccelEventJob = RepeatingTask(
            interval: Double(self.configService.configCache.gyroAccelCadenceTime),
            task: NeuroIDCore.collectGyroAccelEventTask
        )
    }

    func verifyClientKeyExists() -> Bool {
        if self.clientKey == nil || self.clientKey == "" {
            NIDLog.error("Missing Client Key - please call configure prior to calling start")
            return false
        }
        return true
    }

    /// 1. Configure the SDK
    /// 2. Setup silent running loop
    /// 3. Send cached events from DB on a given interval
    func configure(_ configuration: NeuroID.Configuration) -> Bool {
        // set last install time if not already set.
        if getUserDefaultKeyDouble(Constants.lastInstallTime.rawValue) == 0 {
            setUserDefaultKey(Constants.lastInstallTime.rawValue, value: Date().timeIntervalSince1970)
        }

        self.useAdvancedDeviceProxy = configuration.useAdvancedDeviceProxy

        if self.clientKey != nil && self.clientKey != "" {
            NIDLog.error("You already configured the SDK")
            return false
        }

        if !self.validationService.validateClientKey(configuration.clientKey) {
            NIDLog.error("Invalid Client Key")
            self.saveQueuedEventToLocalDataStore(
                NIDEvent.createErrorLogEvent(
                    "Invalid Client Key \(configuration.clientKey)"
                )
            )
            setUserDefaultKey(
                Constants.storageTabIDKey.rawValue, value: ParamsCreator.getTabId() + "-invalid-client-key"
            )

            return false
        }

        self.advancedDeviceKey = configuration.advancedDeviceKey
        self.isAdvancedDevice = configuration.isAdvancedDevice

        if configuration.clientKey.contains("_live_") {
            self.environment = Constants.environmentLive.rawValue
        } else {
            self.environment = Constants.environmentTest.rawValue
        }

        self.clearSessionVariables()

        self.clientKey = configuration.clientKey
        setUserDefaultKey(Constants.storageClientKey.rawValue, value: clientKey)

        // Reset tab id / packet number on configure
        setUserDefaultKey(Constants.storageTabIDKey.rawValue, value: nil)
        self.saveEventToDataStore(
            NIDEvent.createInfoLogEvent("Reset Tab Id")
        )
        self.packetNumber = 0

        self.configService = ConfigService(
            networkService: self.networkService,
            configRetrievalCallback: self.configSetupCompletion
        )

        self.networkMonitor.startMonitoring()

        if isAdvancedDevice {
            self.captureAdvancedDevice(self.isAdvancedDevice)
        }

        self.captureApplicationMetaData()

        self.saveEventToDataStore(
            NIDEvent.createInfoLogEvent("isAdvancedDevice setting: \(isAdvancedDevice)")
        )

        self.configService.retrieveOrRefreshCache()

        return true
    }

    func configSetupCompletion() {
        self.saveEventToLocalDataStore(
            NIDEvent.createInfoLogEvent("Remote Config Retrieval Attempt Completed")
        )
        NIDLog.info("Remote Config Retrieval Attempt Completed")

        self.setupListeners()
    }

    func stop() -> Bool {
        NIDLog.info("NeuroID Stopped")
        do {
            _ = try self.closeSession(skipStop: true)
        } catch {
            NIDLog.error("Failed to Stop because \(error)")
            self.saveEventToDataStore(
                NIDEvent.createErrorLogEvent("Failed to Stop because \(error)")
            )
            return false
        }

        self.send(forceSend: true)
        self._isSDKStarted = false
        self.linkedSiteID = nil

        //  stop listening to changes in call status
        self.callObserver?.stopListeningToCallStatus()
        return true
    }

    func isStopped() -> Bool {
        return self._isSDKStarted != true
    }

    func swizzle() {
        if self.didSwizzle {
            return
        }

        UIViewController.startSwizzling()
        UITextField.startSwizzling()
        UITextView.startSwizzling()
        UINavigationController.swizzleNavigation()
        UITableView.tableviewSwizzle()

        self.didSwizzle.toggle()
    }

    /// Get the current SDK version from bundle
    /// - Returns: String with the version format
    public func getSDKVersion() -> String {
        return ParamsCreator.getSDKVersion()
    }

    func captureApplicationMetaData() {
        let appMetaData = self.getAppMetaData()

        self.eventStorageService.saveEventToDataStore(
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

    func getAppMetaData() -> ApplicationMetaData? {
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
        NIDLog.info("**** NOTE: THIS METHOD IS DEPRECATED AND IS NO LONGER FUNCTIONAL")
    }

    // ENG-9193 - Will remove on next breaking release
    @available(
        *, deprecated,
        message: "printIntegrationHealthInstruction is deprecated and no longer functional"
    )
    public static func setVerifyIntegrationHealth(_ verify: Bool) {
        NIDLog.info("**** NOTE: THIS METHOD IS DEPRECATED AND IS NO LONGER FUNCTIONAL")
    }
}
