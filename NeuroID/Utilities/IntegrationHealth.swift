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
    let orientation = DeviceOrientation(rawValue: device.orientation.rawValue,
                                        isFlat: device.orientation.isFlat,
                                        isPortrait: device.orientation.isPortrait,
                                        isLandscape: device.orientation.isLandscape,
                                        isValid: device.orientation.isValidInterfaceOrientation)

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

    writeDeviceInfoToJSON("\(Contstants.integrationFilePath.rawValue)/\(Contstants.integrationDeviceInfoFile.rawValue)", items: deviceInfo)
}

func generateIntegrationHealthReport(saveCopy: Bool = false) {
    let events = NeuroID.getIntegrationHealthEvents()
//    let events: [NIDEvent] = generateEvents()

    // save to directory where Health Report is HTML is stored
    writeNIDEventsToJSON("\(Contstants.integrationFilePath.rawValue)/\(Contstants.integrationHealthFile.rawValue)", items: events)

    // Save a backup copy that won't be overwritten on next health check
    if saveCopy {
        let fileName = "\(formatDate(date: Date(), dashSeparator: true))-\(Contstants.integrationHealthFile.rawValue)"
        writeNIDEventsToJSON("\(fileName)", items: events)
    }
}

internal extension NeuroID {
    static func shouldDebugIntegrationHealth(_ ifTrueCB: () -> ()) {
        if verifyIntegrationHealth, getEnvironment() == "TEST" {
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
            NIDPrintLog("adding health event \(event.type)")
            NeuroID.debugIntegrationHealthEvents.append(event)
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
    static func printIntegrationHealthInstruction() {
        shouldDebugIntegrationHealth {
            do {
                let serverFile = try getFileURL("\(Contstants.integrationFilePath.rawValue)")

                print("""
                \nℹ️ NeuroID Integration Health Instructions:
                1. Open a terminal command prompt
                2. Cd to \(serverFile.absoluteString.replacingOccurrences(of: "%20", with: "\\ ").replacingOccurrences(of: "file://", with: ""))
                3. Run `node server.js`
                4. Open a web browser to the URL shown in the terminal
                """)
            } catch {}
        }
    }

    static func setVerifyIntegrationHealth(_ verify: Bool) {
        verifyIntegrationHealth = verify

        if verify {
            printIntegrationHealthInstruction()
        }
    }
}

// TESTING FUNCTIONS ONLY
func generateEvents() -> [NIDEvent] {
    let textControl = UITextField()
    textControl.accessibilityIdentifier = "text 1"
    textControl.text = "test Text"

    let textControl2 = UITextField()
    textControl2.accessibilityIdentifier = "text 2"
    textControl2.text = "test Text 2"

    let events = [generateEvent(textControl), generateEvent(textControl, NIDEventName.input),
                  generateEvent(textControl, NIDEventName.textChange), generateEvent(textControl, NIDEventName.registerTarget),
                  generateEvent(textControl, NIDEventName.applicationSubmit), generateEvent(textControl, NIDEventName.createSession),
                  generateEvent(textControl, NIDEventName.blur),

                  generateEvent(textControl2), generateEvent(textControl2, NIDEventName.input),
                  generateEvent(textControl2, NIDEventName.textChange), generateEvent(textControl2, NIDEventName.registerTarget),
                  generateEvent(textControl2, NIDEventName.applicationSubmit), generateEvent(textControl2, NIDEventName.createSession),
                  generateEvent(textControl2, NIDEventName.blur)]

    return events
}

func generateEvent(_ target: UIView, _ eventType: NIDEventName = NIDEventName.textChange) -> NIDEvent {
//    let textValue = target.text ?? ""
//    let lengthValue = "S~C~~\(target.text?.count ?? 0)"

    // Text Change
    let textChangeTG = ["tgs": TargetValue.string(target.id)]
    let textChangeEvent = NIDEvent(type: eventType, tg: textChangeTG)

    return textChangeEvent
}
