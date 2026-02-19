//
//  NIDLog.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation
import OSLog

extension NeuroIDCore {
    /**
     Enable or disable the NeuroID debug logging
     */
    public func enableLogging(_ value: Bool) {
        showLogs = value
    }
}

enum NIDLog {
    private static let nid = Logger(
        subsystem: "com.neuroid.sdk",
        category: "general"
    )

    private static var showLogs: Bool {
        NeuroIDCore.shared.showLogs
    }

    static func log(_ strings: String) {
        guard NeuroIDCore.shared._isSDKStarted, showLogs else { return }
        nid.log("[NeuroID] \(strings)")
    }

    static func debug(_ strings: String) {
        guard NeuroIDCore.shared._isSDKStarted, showLogs else { return }
        nid.debug("[NeuroID Debug] \(strings)")
    }

    static func info(_ strings: String) {
        guard showLogs else { return }
        nid.info("[NeuroID Info] \(strings)")
    }

    static func error(_ strings: String) {
        guard showLogs else { return }
        nid.error("****** NEUROID ERROR: ******\n\(strings)")
    }
}

func NIDPrintEvent(_ mutableEvent: NIDEvent) {
    var contextString = ""

    let tgString = (mutableEvent.tg?.map { key, value in
        let arrayString = value.toArrayString()
        return "\(key): \(arrayString != "" ? arrayString : value.toString())"
    } ?? [""]).joined(separator: ", ")

    let touchesString = (mutableEvent.touches?.map { item in
        "(x=\(String("\(item.x ?? 0)")), y=\(String("\(item.y ?? 0)")), tid=\(String("\(item.tid ?? 0)")))"
    } ?? [""]).joined(separator: ", ")

    let attrsString = (mutableEvent.attrs?.map { item in
        "\(item.n ?? "")=\(item.v ?? "")"
    } ?? [""]).joined(separator: ", ")

    switch mutableEvent.type {
        case NIDEventName.setUserId.rawValue:
            contextString = "uid=\(mutableEvent.uid ?? "")"
        case NIDEventName.createSession.rawValue:
            contextString = "cid=\(mutableEvent.cid ?? ""), sh=\(String(describing: mutableEvent.sh ?? nil)), sw=\(String(describing: mutableEvent.sw ?? nil)), jsv=\(mutableEvent.jsv ?? "")"
        case NIDEventName.applicationSubmit.rawValue:
            contextString = ""
        case NIDEventName.textChange.rawValue:
            contextString = "v=\(mutableEvent.v ?? ""), tg=\(tgString)"
//            case NIDEventName.setCheckpoint.rawValue:
//                contextString = ""
//            case NIDEventName.stateChange.rawValue:
//                contextString = "url=\(mutableEvent.url ?? "")"
        case NIDEventName.keyUp.rawValue:
            contextString = "tg=\(tgString)"
        case NIDEventName.keyDown.rawValue:
            contextString = "tg=\(tgString)"
        case NIDEventName.input.rawValue:
            contextString = "v=\(mutableEvent.v ?? ""), h=\(mutableEvent.hv ?? ""), tg=\(tgString)"
        case NIDEventName.focus.rawValue:
            contextString = ""
        case NIDEventName.blur.rawValue:
            contextString = ""
        case NIDEventName.registerTarget.rawValue:

            contextString = "et=\(mutableEvent.et ?? ""), rts=\(mutableEvent.rts ?? ""), ec=\(mutableEvent.ec ?? ""), v=\(mutableEvent.v ?? ""), tg=[\(tgString)]"
//                 meta=\(String(describing: mutableEvent.metadata ?? nil))
//            case NIDEventName.deregisterTarget.rawValue:
//                contextString = ""
        case NIDEventName.touchStart.rawValue:
            contextString = "xy=[\(touchesString)] tg=\(tgString)"
        case NIDEventName.touchEnd.rawValue:
            contextString = "xy=[\(touchesString)] tg=\(tgString)"
        case NIDEventName.touchMove.rawValue:
            contextString = "xy=[\(touchesString)] tg=\(tgString)"
        case NIDEventName.closeSession.rawValue:
            contextString = ""
        case NIDEventName.setVariable.rawValue:
            contextString = "key=\(mutableEvent.key ?? "Missing Key") v=\(mutableEvent.v ?? "Missing Value")"
        case NIDEventName.customTap.rawValue:
            contextString = "xy=[\(touchesString)] tg=\(tgString) attrs=[\(attrsString)]"
        case NIDEventName.customDoubleTap.rawValue:
            contextString = "xy=[\(touchesString)] tg=\(tgString) attrs=[\(attrsString)]"
        case NIDEventName.customLongPress.rawValue:
            contextString = "xy=[\(touchesString)] tg=\(tgString) attrs=[\(attrsString)]"
        case NIDEventName.customTouchStart.rawValue:
            contextString = "xy=[\(touchesString)] tg=\(tgString) attrs=[\(attrsString)]"
        case NIDEventName.customTouchEnd.rawValue:
            contextString = "xy=[\(touchesString)] tg=\(tgString) attrs=[\(attrsString)]"
        case NIDEventName.cut.rawValue:
            contextString = "v=\(mutableEvent.v ?? ""), h=\(mutableEvent.hv ?? ""), tg=\(tgString)"
        case NIDEventName.copy.rawValue:
            contextString = "v=\(mutableEvent.v ?? ""), h=\(mutableEvent.hv ?? ""), tg=\(tgString)"
        case NIDEventName.paste.rawValue:
            contextString = "v=\(mutableEvent.v ?? ""), h=\(mutableEvent.hv ?? ""), tg=\(tgString)"
        case NIDEventName.windowResize.rawValue:
            contextString = "h=\(mutableEvent.h ?? 0), w=\(mutableEvent.w ?? 0)"
        case NIDEventName.selectChange.rawValue:
            contextString = "tg=\(tgString)"
        case NIDEventName.windowLoad.rawValue:
            contextString = "meta=\(String(describing: mutableEvent.metadata ?? nil))"
        case NIDEventName.windowUnload.rawValue:
            contextString = "meta=\(String(describing: mutableEvent.metadata ?? nil))"
        case NIDEventName.windowBlur.rawValue:
            contextString = "meta=\(String(describing: mutableEvent.metadata ?? nil))"
        case NIDEventName.windowFocus.rawValue:
            contextString = "meta=\(String(describing: mutableEvent.metadata ?? nil))"
        case NIDEventName.deviceOrientation.rawValue:
            contextString = "tg=\(tgString)"
        case NIDEventName.windowOrientationChange.rawValue:
            contextString = "tg=\(tgString)"
        case NIDEventName.log.rawValue:
            contextString = "m=\(mutableEvent.m ?? "")"
        case NIDEventName.advancedDevice.rawValue:
            contextString = "rid=\(mutableEvent.rid ?? "") c=\(mutableEvent.c ?? false) l=\(String(describing: mutableEvent.l)) m=\(mutableEvent.m ?? "")"
        case NIDEventName.callInProgress.rawValue: contextString = "cp=\(String(describing: mutableEvent.cp ?? nil)) attrs=[\(attrsString)]"
        case NIDEventName.mobileMetadataIOS.rawValue:
            contextString = "latong=\(mutableEvent.metadata?.gpsCoordinates.latitude ?? -1), \(mutableEvent.metadata?.gpsCoordinates.longitude ?? -1)"
        case NIDEventName.cadenceReadingAccel.rawValue:
            contextString = "accel=\(mutableEvent.accel?.description ?? "") gyro=\(mutableEvent.gyro?.description ?? "")"
        case NIDEventName.applicationMetaData.rawValue:
            contextString = "attrs=[\(attrsString)]"
        default:
            contextString = ""
    }

    NIDLog.debug("Event: \(mutableEvent.type) - \(mutableEvent.ts) - \(mutableEvent.tgs ?? "NO_TARGET") - \(contextString)")
}
