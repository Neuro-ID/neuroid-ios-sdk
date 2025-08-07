//
//  NIDLog.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation
import os

private enum Log {
    @available(iOS 10.0, *)
    static func log(category: String, contents: Any..., type: OSLogType) {
        #if DEBUG
        if NeuroID.showDebugLog {
            let message = contents.map { "\($0)" }.joined(separator: " ")
            os_log("NeuroID: %@", message)
        }
        #endif
    }
}

extension NeuroID {
    /**
     Enable or disable the NeuroID debug logging
     */
    public static func enableLogging(_ value: Bool) {
        showLogs = value
    }

    static func logInfo(category: String = "default", content: Any...) {
        osLog(category: category, content: content, type: .info)
    }

    static func logError(category: String = "default", content: Any...) {
        osLog(category: category, content: content, type: .error)
    }

    static func logFault(category: String = "default", content: Any...) {
        osLog(category: category, content: content, type: .fault)
    }

    static func logDebug(category: String = "default", content: Any...) {
        osLog(category: category, content: content, type: .debug)
    }

    static func logDefault(category: String = "default", content: Any...) {
        osLog(category: category, content: content, type: .default)
    }

    private static func osLog(category: String = "default", content: Any..., type: OSLogType) {
        Log.log(category: category, contents: content, type: .info)
    }

    /**
     Save the params being sent to POST to collector endpoint to a local file
     */
    static func saveDebugJSON(events: String) {
        let jsonStringNIDEvents = "\(events)".data(using: .utf8)!
        do {
            let filemgr = FileManager.default
            let path = filemgr.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(Constants.debugJsonFileName.rawValue)
            if !filemgr.fileExists(atPath: path.path) {
                filemgr.createFile(atPath: path.path, contents: jsonStringNIDEvents, attributes: nil)

            } else {
                let file = FileHandle(forReadingAtPath: path.path)
                if let fileUpdater = try? FileHandle(forUpdating: path) {
                    // Function which when called will cause all updates to start from end of the file
                    fileUpdater.seekToEndOfFile()

                    // Which lets the caller move editing to any position within the file by supplying an offset
                    fileUpdater.write(",\n".data(using: .utf8)!)
                    fileUpdater.write(jsonStringNIDEvents)
                } else {
                    logger.e("Unable to append DEBUG JSON")
                }
            }
        } catch {
            logger.e(String(describing: error))
        }
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
        case NIDSessionEventName.setUserId.rawValue:
            contextString = "uid=\(mutableEvent.uid ?? "")"
        case NIDSessionEventName.createSession.rawValue:
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
        case NIDSessionEventName.setVariable.rawValue:
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

    NIDLog().d(
        tag: "Event:",
        "\(mutableEvent.type) - \(mutableEvent.ts) - \(mutableEvent.tgs ?? "NO_TARGET") - \(contextString)"
    )
}

// Protocols don't allow optional args so we need to allow both with and
//  without tags
protocol LoggerProtocol {
    func log(_ strings: String)
    func log(tag: String, _ strings: String)

    func d(_ strings: String)
    func d(tag: String, _ strings: String)

    func i(_ strings: String)
    func i(tag: String, _ strings: String)

    func e(_ strings: String)
    func e(tag: String, _ strings: String)
}

class NIDLog: LoggerProtocol {
    func log(_ strings: String) {
        log(tag: "", strings)
    }

    func log(tag: String = "", _ strings: String) {
        if NeuroID._isSDKStarted, NeuroID.showLogs {
            Swift.print("(NeuroID) \(tag) ", strings)
        }
    }

    func d(_ strings: String) {
        d(tag: "", strings)
    }

    func d(tag: String = "", _ strings: String) {
        if NeuroID._isSDKStarted, NeuroID.showLogs {
            Swift.print("(NeuroID Debug) \(tag) ", strings)
        }
    }

    func i(_ strings: String) {
        i(tag: "", strings)
    }

    func i(tag: String = "", _ strings: String) {
        if NeuroID.showLogs {
            Swift.print("(NeuroID Info) \(tag) ", strings)
        }
    }

    func e(_ strings: String) {
        e(tag: "", strings)
    }

    func e(tag: String = "", _ strings: String) {
        if NeuroID.showLogs {
            Swift.print("****** NEUROID ERROR: ******\n\(tag) ", strings)
        }
    }
}
