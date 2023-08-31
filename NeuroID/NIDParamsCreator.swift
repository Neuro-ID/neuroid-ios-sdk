//
//  NIDParamsCreator.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/30/23.
//

import Foundation
import UIKit

// MARK: - Properties - temporary public for testing

enum ParamsCreator {
    static func getTgParams(view: UIView, extraParams: [String: TargetValue] = [:]) -> [String: TargetValue] {
        // TODO, figure out if we need to find super class of ETN
        var params: [String: TargetValue] = [
            "\(Constants.tgsKey.rawValue)": TargetValue.string(view.id),
            "\(Constants.etnKey.rawValue)": TargetValue.string(view.className),
        ]

        for (key, value) in extraParams {
            params[key] = value
        }
        return params
    }

    static func getTimeStamp() -> Int64 {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        return now
    }

    static func getTGParamsForInput(
        eventName: NIDEventName,
        view: UIView,
        type: String,
        extraParams: [String: TargetValue] = [:],
        attrParams: [String: Any]?
    ) -> [String: TargetValue] {
        var params: [String: TargetValue] = [:]

        switch eventName {
        case .focus, .blur, .textChange, .radioChange,
             .checkboxChange, .input, .copy, .paste, .click:

            let inputValue = attrParams?["\(Constants.vKey.rawValue)"] as? String ?? "\(Constants.eventValuePrefix.rawValue)"
            let textValue = attrParams?["\(Constants.hashKey.rawValue)"] as? String ?? ""

            let attrArraryVal: [Attr] = [
                Attr(n: "\(Constants.vKey.rawValue)", v: inputValue),
                Attr(n: "\(Constants.hashKey.rawValue)", v: textValue.hashValue()),
            ]

            params = [
                "\(Constants.tgsKey.rawValue)": TargetValue.string(view.id),
                "\(Constants.etnKey.rawValue)": TargetValue.string(view.id),
                "\(Constants.etKey.rawValue)": TargetValue.string(type),
                "\(Constants.attrKey.rawValue)": TargetValue.attr(attrArraryVal),
            ]

        case .keyDown:
            params = [
                "\(Constants.tgsKey.rawValue)": TargetValue.string(view.id),
            ]
        default:
            print("Invalid type")
        }
        for (key, value) in extraParams {
            params[key] = value
        }
        return params
    }

    static func getUiControlTgParams(sender: UIView) -> [String: TargetValue] {
        var tg: [String: TargetValue] = [
            "sender": TargetValue.string(sender.className),
            "\(Constants.tgsKey.rawValue)": TargetValue.string(sender.id),
        ]

        if let control = sender as? UISwitch {
            tg["oldValue"] = TargetValue.bool(!control.isOn)
            tg["newValue"] = TargetValue.bool(control.isOn)

        } else if let control = sender as? UISegmentedControl {
            tg["\(Constants.valueKey.rawValue)"] = TargetValue.string((control.titleForSegment(at: control.selectedSegmentIndex) ?? "").hashValue())
            tg["selectedIndex"] = TargetValue.int(control.selectedSegmentIndex)

        } else if let control = sender as? UIStepper {
            tg["\(Constants.valueKey.rawValue)"] = TargetValue.double(control.value)

        } else if let control = sender as? UISlider {
            tg["\(Constants.valueKey.rawValue)"] = TargetValue.double(Double(control.value))

        } else if let control = sender as? UIDatePicker {
            tg["\(Constants.valueKey.rawValue)"] = TargetValue.string("\(Constants.eventValuePrefix.rawValue)\(control.date.toString().count)")
        }
        return tg
    }

    static func getOrientation() -> String {
        let orientation: String
        if UIDevice.current.orientation.isLandscape {
            orientation = Constants.orientationLandscape.rawValue
        } else {
            orientation = Constants.orientationPortrait.rawValue
        }

        return orientation
    }

    static func getTabId() -> String {
        let tabIdName = Constants.storageTabIdKey.rawValue
        let tid = getUserDefaultKeyString(tabIdName)

        if tid != nil && !tid!.contains("-") {
            return tid!
        } else {
            let randString = genId()
            let tid = randString.replacingOccurrences(of: "-", with: "").prefix(12)
            setUserDefaultKey(tabIdName, value: tid)
            return "\(tid)"
        }
    }

    static func getDeviceId() -> String {
        let deviceIdCacheKey = Constants.storageDeviceIdKey.rawValue
        var did = getUserDefaultKeyString(deviceIdCacheKey)

        if did != nil && did!.contains("_") {
            return did!
        } else {
            did = genId()
            setUserDefaultKey(deviceIdCacheKey, value: did)
            return did!
        }
    }

    internal static func genId() -> String {
        return UUID().uuidString
    }

    static func getDnt() -> Bool {
        let dnt = getUserDefaultKeyString(Constants.storageDntKey.rawValue)
        // If there is ANYTHING set in nid_dnt, we return true (meaning don't track)
        if dnt != nil {
            return true
        } else {
            return false
        }
    }

    // Obviously, being a phone we always support touch
    static func getTouch() -> Bool {
        return true
    }

    static func getPlatform() -> String {
        return "Apple"
    }

    static func getLocale() -> String {
        return Locale.current.identifier
    }

    static func getUserAgent() -> String {
        return "iOS " + UIDevice.current.systemVersion
    }

    // Minutes from GMT
    static func getTimezone() -> Int {
        let timezone = TimeZone.current.secondsFromGMT() / 60
        return timezone
    }

    static func getLanguage() -> String {
        let locale = Locale.current.languageCode
        return locale ?? Locale.current.identifier
    }

    /** Start with primar JS version as TrackJS requires to force correct session structure */
    static func getSDKVersion() -> String {
        // Version MUST start with 4. in order to be processed correctly
        let version = Bundle(for: NeuroIDTracker.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return "5.ios-\(version ?? "?")"
    }

    static func getCommandQueueNamespace() -> String {
        return "nid"
    }

    static func generateUniqueHexId() -> String {
        let x = 1
        let now = Date().timeIntervalSince1970 * 1000
        let rawId = (Int(now) - 1488084578518) * 1024 + (x + 1)
        return String(format: "%02X", rawId)
    }
}
