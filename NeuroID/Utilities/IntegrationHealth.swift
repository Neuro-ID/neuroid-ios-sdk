//
//  IntegrationHealth.swift
//  NeuroID
//
//  Created by Kevin Sites on 4/20/23.
//

import Foundation
import UIKit

struct IntegrationHealthDeviceInfo: Codable {
    var name: String
    var systemName: String
    var systemVersion: String
    var isSimulator: Bool
    var Orientation: DeviceOrientation // different type

    var model: String
    var type: String
    var customDeviceType: String

    var nidSDKVersion: String
}

struct DeviceOrientation: Codable {
    var rawValue: Int
    var isFlat: Bool
    var isPortrait: Bool
    var isLandscape: Bool
    var isValid: Bool
}

func formatDate(date: Date, dashSeparator: Bool = false) -> String {
    let df = DateFormatter()
    let timeFormat = dashSeparator ? "hh-mm-ss" : "hh:mm:ss"
    df.dateFormat = "yyyy-MM-dd \(timeFormat)"
    let now = df.string(from: date)

    return now
}

func generateIntegrationHealthDeviceReport(_ device: UIDevice) {
    let orientation = DeviceOrientation(
        rawValue: device.orientation.rawValue,
        isFlat: device.orientation.isFlat,
        isPortrait: device.orientation.isPortrait,
        isLandscape: device.orientation.isLandscape,
        isValid: device.orientation.isValidInterfaceOrientation
    )

    let deviceInfo = IntegrationHealthDeviceInfo(
        name: device.name,
        systemName: device.systemName,
        systemVersion: device.systemVersion,
        isSimulator: device.isSimulator,
        Orientation: orientation,
        model: device.model,
        type: device.type.rawValue,
        customDeviceType: "",
        nidSDKVersion: NeuroID.getSDKVersion() ?? "1.0.0"
    )

    do {
        try? writeDeviceInfoToJSON(
            "\(Constants.integrationFilePath.rawValue)/\(Constants.integrationDeviceInfoFile.rawValue)",
            items: deviceInfo
        )
    }
}

func generateIntegrationHealthReport(saveCopy: Bool = false) {
    let events = NeuroID.getIntegrationHealthEvents()

    // save to directory where Health Report is HTML is stored
    do {
        try? writeNIDEventsToJSON("\(Constants.integrationFilePath.rawValue)/\(Constants.integrationHealthFile.rawValue)", items: events)
    }

    // Save a backup copy that won't be overwritten on next health check
    if saveCopy {
        let fileName = "\(formatDate(date: Date(), dashSeparator: true))-\(Constants.integrationHealthFile.rawValue)"
        do {
            try? writeNIDEventsToJSON("\(fileName)", items: events)
        }
    }
}

func saveIntegrationHealthResources() {
    if let bundleURL = Bundle(for: NeuroIDTracker.self).url(forResource: Constants.integrationHealthResourceBundle.rawValue, withExtension: "bundle")

    {
        let NIDDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent(Constants.integrationFilePath.rawValue)

        do {
            // Copy Static Folder (Css/Js)
            try? copyResourceBundleFolder(folderName: "static", fileDirectory: NIDDirectory, bundleURL: bundleURL)

            // copy Index HTML
            try? copyResourceBundleFile(fileName: "index.html", fileDirectory: NIDDirectory, bundleURL: bundleURL)

            // copy Server.JS
            try? copyResourceBundleFile(fileName: "server.js", fileDirectory: NIDDirectory, bundleURL: bundleURL)
        }
    }
}

internal extension NeuroID {
    static func shouldDebugIntegrationHealth(_ ifTrueCB: () -> ()) {
        if verifyIntegrationHealth, getEnvironment() == Constants.environmentTest.rawValue {
            ifTrueCB()
        }
    }

    static func startIntegrationHealthCheck() {
        shouldDebugIntegrationHealth {
            debugIntegrationHealthEvents = []
            generateIntegrationHealthDeviceReport(UIDevice.current)
            generateNIDIntegrationHealthReport()
        }
    }

    static func captureIntegrationHealthEvent(_ event: NIDEvent) {
        shouldDebugIntegrationHealth {
            NIDDebugPrint(tag: "\(Constants.integrationHealthTag.rawValue)", "Adding NID Health Event \(event.type)")
            debugIntegrationHealthEvents.append(event)
        }
    }

    static func getIntegrationHealthEvents() -> [NIDEvent] {
        return debugIntegrationHealthEvents
    }

    static func saveIntegrationHealthEvents() {
        shouldDebugIntegrationHealth {
            generateNIDIntegrationHealthReport()
        }
    }

    static func generateNIDIntegrationHealthReport(saveIntegrationHealthReport: Bool = false) {
        shouldDebugIntegrationHealth {
            generateIntegrationHealthReport(saveCopy: saveIntegrationHealthReport)
        }
    }
}

public extension NeuroID {
    static func printIntegrationHealthInstruction() -> String {
        var instructions = ""

        shouldDebugIntegrationHealth {
            do {
                let serverFile = try getFileURL("\(Constants.integrationFilePath.rawValue)")
                instructions = """
                    \n\n   **************************************************************
                    \n      ℹ️ NeuroID Integration Health Instructions:
                        1. Open a terminal command prompt
                        2. Cd to \(serverFile.absoluteString.replacingOccurrences(of: "%20", with: "\\ ").replacingOccurrences(of: "file://", with: ""))
                        3. Run `node server.js`
                        4. Open a web browser to the URL shown in the terminal
                   \n   **************************************************************
                    \n\n
                """
                print(instructions)
            } catch {}
            saveIntegrationHealthResources()
            startIntegrationHealthCheck()
        }
        return instructions
    }

    static func setVerifyIntegrationHealth(_ verify: Bool) -> String {
        verifyIntegrationHealth = verify
        var instructions = ""
        if verify {
            instructions = printIntegrationHealthInstruction()
        }
        return instructions
    }
}
