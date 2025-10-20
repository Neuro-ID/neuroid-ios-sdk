//
//  NIDMetadata.swift
//  NeuroID
//
//  Created by jose perez on 26/08/22.
//

import CoreTelephony
import Foundation
import Network
import SwiftUI
import UIKit
import DeviceKit

struct NIDLocation: Codable {
    var latitude: Double?
    var longitude: Double?
    var authorizationStatus: String
}

struct NIDMetadata: Codable {
    var brand: String
    var device: String
    var display: String
    var manufacturer: String
    var model: String
    var product: String
    var osVersion: String
    var displayResolution: String
    var carrier: String
    var batteryLevel: Double
    var isJailBreak: Bool
    var isWifiOn: Bool
    var isSimulator: Bool
    var gpsCoordinates: NIDLocation
    var lastInstallTime: Int64

    // Init with local data
    public init() {
        self.brand = UIDevice.current.model
        self.device = NIDMetadata.getDeviceName()
        self.display = NIDMetadata.getDisplay()
        self.displayResolution = NIDMetadata.getDisplayResolution()
        self.manufacturer = NIDMetadata.getDeviceManufacturer()
        self.model = NIDMetadata.getDeviceModel()
        self.product = NIDMetadata.getDeviceName()
        self.osVersion = NIDMetadata.getOSVersion()
        self.isWifiOn = NIDMetadata.isWifiEnable()
        self.carrier = NIDMetadata.getCurrentCarrier()
        self.batteryLevel = NIDMetadata.getBaterryLevel()
        self.isJailBreak = NIDMetadata.hasJailbreak()
        self.isSimulator = NIDMetadata.isSimulator()
        self.lastInstallTime = Int64(getUserDefaultKeyDouble(Constants.lastInstallTime.rawValue) * 1000)
        self.gpsCoordinates = NIDLocation(
            latitude: NeuroID.shared.locationManager?.latitude ?? -1,
            longitude: NeuroID.shared.locationManager?.longitude ?? -1,
            authorizationStatus: NeuroID.shared.locationManager?.authorizationStatus ?? "unknown"
        )
    }
}

// MARK: - Static funtions

extension NIDMetadata {
    static func getDeviceName() -> String {
        // Intentionally returns an empty string to avoid collecting PII
        return ""
    }

    static func getDeviceModel() -> String {
        let device = Device.current

        if case .unknown = device { 
            return "?unrecognized?"
        }

        return device.description
    }

    static func getDisplay() -> String {
        return self.getDeviceManufacturer()
    }

    static func getDisplayResolution() -> String {
        let screenSize = UIScreen.main.bounds
        return "\(screenSize.width),\(screenSize.height)"
    }

    static func getDeviceManufacturer() -> String {
        let uniqueID: String = UIDevice.current.identifierForVendor?.uuidString ?? ""
        return uniqueID
    }

    static func getOSVersion() -> String {
        let name = UIDevice.current.systemName // eg. iOS
        let version = UIDevice.current.systemVersion // eg. 26.0
        return name + version
    }

    static func getCurrentCarrier() -> String {
        if #available(iOS 12.0, *) {
            let coreTelephony = CTTelephonyNetworkInfo()
            var current = ""
            var name = ""
            if #available(iOS 13.0, *) {
                if let currentName = coreTelephony.dataServiceIdentifier {
                    name = currentName
                }
            }
            if let data = coreTelephony.serviceSubscriberCellularProviders, let carrierName = data[name]?.carrierName {
                current = carrierName
            }
            return current
        } else {
            return ""
        }
    }

    static func getBaterryLevel() -> Double {
        return Double(Device.current.batteryLevel ?? 0)
    }

    static func hasJailbreak() -> Bool {
        // Never report jailbreak on simulator
        guard !UIDevice.current.isSimulator else { return false }

        // Any of these checks indicate a jailbreak
        return self.isCydiaAppInstalled()
            || self.isContainsSuspiciousApps()
            || self.isSuspiciousSystemPathsExists()
            || self.canEditSystemFiles()
    }

    static func isSimulator() -> Bool {
        return UIDevice.current.isSimulator
    }

    static func isWifiEnable() -> Bool {
        if #available(iOS 12.0, *) {
            let networkStatus = NetworkStatus.shared
            networkStatus.start()
            networkStatus.stop()
            return networkStatus.connType == .wifi
        } else {
            return false
        }
    }

    @available(iOSApplicationExtension, unavailable)
    static func isCydiaAppInstalled() -> Bool {
        return UIApplication.shared.canOpenURL(URL(string: "cydia://")!)
    }

    // Check if system contains suspicious files
    static func isSuspiciousSystemPathsExists() -> Bool {
        for path in self.suspiciousSystemPathsToCheck {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }

    static func isContainsSuspiciousApps() -> Bool {
        for path in self.suspiciousAppsPathToCheck {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }

    // Check if app can edit system files
    static func canEditSystemFiles() -> Bool {
        let jailBreakText = "Developer Insider"
        do {
            try jailBreakText.write(toFile: jailBreakText, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }

    // suspicious apps path to check
    static var suspiciousAppsPathToCheck: [String] {
        return ["/Applications/Cydia.app",
                "/Applications/blackra1n.app",
                "/Applications/FakeCarrier.app",
                "/Applications/Icy.app",
                "/Applications/IntelliScreen.app",
                "/Applications/MxTube.app",
                "/Applications/RockApp.app",
                "/Applications/SBSettings.app",
                "/Applications/WinterBoard.app"]
    }

    // suspicious system paths to check
    static var suspiciousSystemPathsToCheck: [String] {
        return ["/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
                "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
                "/private/var/lib/apt",
                "/private/var/lib/apt/",
                "/private/var/lib/cydia",
                "/private/var/mobile/Library/SBSettings/Themes",
                "/private/var/stash",
                "/private/var/tmp/cydia.log",
                "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
                "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
                "/usr/bin/sshd",
                "/usr/libexec/sftp-server",
                "/usr/sbin/sshd",
                "/etc/apt",
                "/bin/bash",
                "/Library/MobileSubstrate/MobileSubstrate.dylib"]
    }
}

extension UIDevice {
    var isSimulator: Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }
}

@available(iOS 12.0, *)
class NetworkStatus {
    public static let shared = NetworkStatus()
    private var monitor: NWPathMonitor
    private var queue = DispatchQueue.global()
    var isOn: Bool = true
    var connType: ConnectionType = .unknown
    private init() {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue.global(qos: .userInitiated)
        self.monitor.start(queue: self.queue)
    }

    func start() {
        self.connType = self.checkConnectionTypeForPath(self.monitor.currentPath)
        self.monitor.pathUpdateHandler = { path in
            self.isOn = path.status == .satisfied
            self.connType = self.checkConnectionTypeForPath(path)
        }
    }

    func stop() {
        self.monitor.cancel()
    }

    func checkConnectionTypeForPath(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        }
        return .unknown
    }
}
