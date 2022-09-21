//
//  NIDMetadata.swift
//  NeuroID
//
//  Created by jose perez on 26/08/22.
//

import Foundation
import UIKit
import AVFoundation
import CoreTelephony
import Network
import SwiftUI
    


final public class NIDMetadata: Codable {
    var brand: String
    var device: String
    var display: String
    var manufacturer: String
    var model: String
    var product: String
    var osVersion: String
    var displayResolution: String
    var carrier: String
    var totalMemory: Double
    var batteryLevel: Double
    var isJailBreak: Bool
    var isWifiOn:Bool
    var isSimulator:Bool
    
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
        self.totalMemory = NIDMetadata.getTotalMemory()
        self.batteryLevel = NIDMetadata.getBaterryLevel()
        self.isJailBreak = NIDMetadata.hasJailbreak()
        self.isSimulator = NIDMetadata.isSimulator()
    }
}

// MARK: - Static funtions
extension NIDMetadata {
    static func getDeviceName() -> String {
        return UIDevice.current.name
    }
    static func getDeviceModel() -> String {
        return UIDevice.current.type.rawValue
    }
    static func getDisplay() -> String {
        return getDeviceManufacturer()
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
        let name = UIDevice.current.systemName
        let version = UIDevice.current.systemVersion
        return name + version
    }
    static func getCurrentCarrier() -> String {
        if #available(iOS 12.0, *) {
              let carriers = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?.values
            let current = carriers?.first?.carrierName ?? ""
            return current
        } else {
            return ""
        }
    }
    static func getTotalMemory() -> Double {
        do {
            let url = NSURL.init(fileURLWithPath: NSHomeDirectory())
            let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityKey, .volumeTotalCapacityKey])
            let capacity = values[.volumeTotalCapacityKey] as! Double
            let storage = capacity / (1048576 * 1024)
            return storage
        } catch {
            #if DEBUG
            print(error)
            #endif
        }
        return 0.0
    }
    static func getBaterryLevel() -> Double {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return Double(UIDevice.current.batteryLevel) * 100.0
    }
    static func hasJailbreak() -> Bool {
        if UIDevice.current.isSimulator { return false }
        if self.isCydiaAppInstalled() { return true }
        if self.isContainsSuspiciousApps() { return true }
        if self.isSuspiciousSystemPathsExists() { return true }
        return self.canEditSystemFiles()
        
    }
    
    static func isSimulator() -> Bool {
        if UIDevice.current.isSimulator { return true }
        return false
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
    
    static func isCydiaAppInstalled() -> Bool {
        return UIApplication.shared.canOpenURL(URL(string: "cydia://")!)
    }
    
    //Check if system contains suspicious files
    static func isSuspiciousSystemPathsExists() -> Bool {
        for path in suspiciousSystemPathsToCheck {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }
    
    static func isContainsSuspiciousApps() -> Bool {
        for path in suspiciousAppsPathToCheck {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }
    
    //Check if app can edit system files
    static func canEditSystemFiles() -> Bool {
        let jailBreakText = "Developer Insider"
        do {
            try jailBreakText.write(toFile: jailBreakText, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }
    
    //suspicious apps path to check
    static var suspiciousAppsPathToCheck: [String] {
        return ["/Applications/Cydia.app",
                "/Applications/blackra1n.app",
                "/Applications/FakeCarrier.app",
                "/Applications/Icy.app",
                "/Applications/IntelliScreen.app",
                "/Applications/MxTube.app",
                "/Applications/RockApp.app",
                "/Applications/SBSettings.app",
                "/Applications/WinterBoard.app"
        ]
    }
    
    //suspicious system paths to check
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
                "/Library/MobileSubstrate/MobileSubstrate.dylib"
        ]
    }
}
extension UIDevice {
    var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
}
public enum ConnectionType: String {
    case wifi
    case ethernet
    case cellular
    case unknown
}

@available(iOS 12.0, *)
class NetworkStatus {
    static public let shared = NetworkStatus()
    private var monitor: NWPathMonitor
    private var queue = DispatchQueue.global()
    var isOn: Bool = true
    var connType: ConnectionType = .unknown
    private init() {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue.global(qos: .userInitiated)
        self.monitor.start(queue: queue)
    }
    func start() {
        self.connType = checkConnectionTypeForPath(self.monitor.currentPath)
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
public enum Model : String {

    case simulator     = "simulator",

    iPod1              = "iPod 1",
    iPod2              = "iPod 2",
    iPod3              = "iPod 3",
    iPod4              = "iPod 4",
    iPod5              = "iPod 5",

    iPad2              = "iPad 2",
    iPad3              = "iPad 3",
    iPad4              = "iPad 4",
    iPadAir            = "iPad Air ",
    iPadAir2           = "iPad Air 2",
    iPadAir3           = "iPad Air 3",
    iPad5              = "iPad 5",
    iPad6              = "iPad 6",
    iPad7              = "iPad 7",

    iPadMini           = "iPad Mini",
    iPadMini2          = "iPad Mini 2",
    iPadMini3          = "iPad Mini 3",
    iPadMini4          = "iPad Mini 4",
    iPadMini5          = "iPad Mini 5",

    iPadPro9_7         = "iPad Pro 9.7\"",
    iPadPro10_5        = "iPad Pro 10.5\"",
    iPadPro11          = "iPad Pro 11\"",
    iPadPro12_9        = "iPad Pro 12.9\"",
    iPadPro2_12_9      = "iPad Pro 2 12.9\"",
    iPadPro3_12_9      = "iPad Pro 3 12.9\"",

    iPhone4            = "iPhone 4",
    iPhone4S           = "iPhone 4S",
    iPhone5            = "iPhone 5",
    iPhone5S           = "iPhone 5S",
    iPhone5C           = "iPhone 5C",
    iPhone6            = "iPhone 6",
    iPhone6Plus        = "iPhone 6 Plus",
    iPhone6S           = "iPhone 6S",
    iPhone6SPlus       = "iPhone 6S Plus",
    iPhoneSE           = "iPhone SE",
    iPhone7            = "iPhone 7",
    iPhone7Plus        = "iPhone 7 Plus",
    iPhone8            = "iPhone 8",
    iPhone8Plus        = "iPhone 8 Plus",
    iPhoneX            = "iPhone X",
    iPhoneXS           = "iPhone XS",
    iPhoneXSMax        = "iPhone XS Max",
    iPhoneXR           = "iPhone XR",
    iPhone11           = "iPhone 11",
    iPhone11Pro        = "iPhone 11 Pro",
    iPhone11ProMax     = "iPhone 11 Pro Max",
    iPhoneSE_2nd_Gen   = "iPhone SE 2nd Gen",
    iPhone12Mini       = "iPhone 12 Mini",
    iPhone12           = "iPhone 12",
    iPhone12Pro        = "iPhone 12 Pro",
    iPhone12ProMax     = "iPhone 12 Pro Max",
    iPhone13Pro        = "iPhone 13 Pro",
    iPhone13ProMax     = "iPhone 13 Pro Max",
    iPhone13Mini       = "iPhone 13 Mini",
    iPhone13           = "iPhone 13",
    iPhoneSE_3rd_Gen   = "iPhone SE 3rd Gen",
    iPhone14           = "iPhone 14",
    iPhone14Plus       = "iPhone 14 Plus",
    iPhone14Pro        = "iPhone 14 Pro",
    iPhone14ProMax     = "iPhone 14 Pro Max",

    AppleTV            = "Apple TV",
    AppleTV_4K         = "Apple TV 4K",
    unrecognized       = "?unrecognized?"
}

public extension UIDevice {

    var type: Model {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }

        let modelMap : [String: Model] = [
            "i386"      : .simulator,
            "x86_64"    : .simulator,

            "iPod1,1"   : .iPod1,
            "iPod2,1"   : .iPod2,
            "iPod3,1"   : .iPod3,
            "iPod4,1"   : .iPod4,
            "iPod5,1"   : .iPod5,

            "iPad2,1"   : .iPad2,
            "iPad2,2"   : .iPad2,
            "iPad2,3"   : .iPad2,
            "iPad2,4"   : .iPad2,
            "iPad3,1"   : .iPad3,
            "iPad3,2"   : .iPad3,
            "iPad3,3"   : .iPad3,
            "iPad3,4"   : .iPad4,
            "iPad3,5"   : .iPad4,
            "iPad3,6"   : .iPad4,
            "iPad6,11"  : .iPad5,
            "iPad6,12"  : .iPad5,
            "iPad7,5"   : .iPad6,
            "iPad7,6"   : .iPad6,
            "iPad7,11"  : .iPad7,
            "iPad7,12"  : .iPad7,

            "iPad2,5"   : .iPadMini,
            "iPad2,6"   : .iPadMini,
            "iPad2,7"   : .iPadMini,
            "iPad4,4"   : .iPadMini2,
            "iPad4,5"   : .iPadMini2,
            "iPad4,6"   : .iPadMini2,
            "iPad4,7"   : .iPadMini3,
            "iPad4,8"   : .iPadMini3,
            "iPad4,9"   : .iPadMini3,
            "iPad5,1"   : .iPadMini4,
            "iPad5,2"   : .iPadMini4,
            "iPad11,1"  : .iPadMini5,
            "iPad11,2"  : .iPadMini5,

            "iPad6,3"   : .iPadPro9_7,
            "iPad6,4"   : .iPadPro9_7,
            "iPad7,3"   : .iPadPro10_5,
            "iPad7,4"   : .iPadPro10_5,
            "iPad6,7"   : .iPadPro12_9,
            "iPad6,8"   : .iPadPro12_9,
            "iPad7,1"   : .iPadPro2_12_9,
            "iPad7,2"   : .iPadPro2_12_9,
            "iPad8,1"   : .iPadPro11,
            "iPad8,2"   : .iPadPro11,
            "iPad8,3"   : .iPadPro11,
            "iPad8,4"   : .iPadPro11,
            "iPad8,5"   : .iPadPro3_12_9,
            "iPad8,6"   : .iPadPro3_12_9,
            "iPad8,7"   : .iPadPro3_12_9,
            "iPad8,8"   : .iPadPro3_12_9,

            "iPad4,1"   : .iPadAir,
            "iPad4,2"   : .iPadAir,
            "iPad4,3"   : .iPadAir,
            "iPad5,3"   : .iPadAir2,
            "iPad5,4"   : .iPadAir2,
            "iPad11,3"  : .iPadAir3,
            "iPad11,4"  : .iPadAir3,

            "iPhone3,1" : .iPhone4,
            "iPhone3,2" : .iPhone4,
            "iPhone3,3" : .iPhone4,
            "iPhone4,1" : .iPhone4S,
            "iPhone5,1" : .iPhone5,
            "iPhone5,2" : .iPhone5,
            "iPhone5,3" : .iPhone5C,
            "iPhone5,4" : .iPhone5C,
            "iPhone6,1" : .iPhone5S,
            "iPhone6,2" : .iPhone5S,
            "iPhone7,1" : .iPhone6Plus,
            "iPhone7,2" : .iPhone6,
            "iPhone8,1" : .iPhone6S,
            "iPhone8,2" : .iPhone6SPlus,
            "iPhone8,4" : .iPhoneSE,
            "iPhone9,1" : .iPhone7,
            "iPhone9,3" : .iPhone7,
            "iPhone9,2" : .iPhone7Plus,
            "iPhone9,4" : .iPhone7Plus,
            "iPhone10,1" : .iPhone8,
            "iPhone10,4" : .iPhone8,
            "iPhone10,2" : .iPhone8Plus,
            "iPhone10,5" : .iPhone8Plus,
            "iPhone10,3" : .iPhoneX,
            "iPhone10,6" : .iPhoneX,
            "iPhone11,2" : .iPhoneXS,
            "iPhone11,4" : .iPhoneXSMax,
            "iPhone11,6" : .iPhoneXSMax,
            "iPhone11,8" : .iPhoneXR,
            "iPhone12,1" : .iPhone11,
            "iPhone12,3" : .iPhone11Pro,
            "iPhone12,5" : .iPhone11ProMax,
            "iPhone12,8" : .iPhoneSE_2nd_Gen,
            "iPhone13,1" : .iPhone12Mini,
            "iPhone13,2" : .iPhone12,
            "iPhone13,3" : .iPhone12Pro,
            "iPhone13,4" : .iPhone12ProMax,
            "iPhone14,2" : .iPhone13Pro,
            "iPhone14,3" : .iPhone13ProMax,
            "iPhone14,4" : .iPhone13Mini,
            "iPhone14,5" : .iPhone13,
            "iPhone14,6" : .iPhoneSE_3rd_Gen,
            "iPhone14,7" : .iPhone14,
            "iPhone14,8" : .iPhone14Plus,
            "iPhone15,2" : .iPhone14Pro,
            "iPhone15,3" : .iPhone14ProMax,

            "AppleTV5,3" : .AppleTV,
            "AppleTV6,2" : .AppleTV_4K
        ]

        if let model = modelMap[String.init(validatingUTF8: modelCode!)!] {
            if model == .simulator {
                if let simModelCode = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
                    if let simModel = modelMap[String.init(validatingUTF8: simModelCode)!] {
                        return simModel
                    }
                }
            }
            return model
        }
        return Model.unrecognized
    }
}
