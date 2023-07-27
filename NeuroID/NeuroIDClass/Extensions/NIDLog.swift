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

public extension NeuroID {
    /**
     Enable or disable the NeuroID debug logging
     */
    static func enableLogging(_ value: Bool) {
        logVisible = value
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
    internal static func saveDebugJSON(events: String) {
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
                    print("Unable to append DEBUG JSON")
                }
            }
        } catch {
            print(String(describing: error))
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
        "x=\(String("\(item.x ?? 0)")), y=\(String("\(item.y ?? 0)")), tid=\(String("\(item.tid ?? 0)"))"
    } ?? [""]).joined(separator: ", ")

    let attrsString = (mutableEvent.attrs?.map { item in
        "\(item.n ?? "")=\(item.v ?? "")"
    } ?? [""]).joined(separator: ", ")

    switch mutableEvent.type {
        case NIDSessionEventName.setUserId.rawValue:
            contextString = "uid=\(mutableEvent.uid ?? "")"

        case NIDSessionEventName.createSession.rawValue:
            contextString = "cid=\(mutableEvent.cid ?? ""), sh=\(String(describing: mutableEvent.sh ?? nil)), sw=\(String(describing: mutableEvent.sw ?? nil))"

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
            contextString = "xy=\(touchesString) tg=\(tgString)"
        case NIDEventName.touchEnd.rawValue:
            contextString = "xy=\(touchesString) tg=\(tgString)"
        case NIDEventName.touchMove.rawValue:
            contextString = "xy=\(touchesString) tg=\(tgString)"
        case NIDEventName.closeSession.rawValue:
            contextString = ""
//            case NIDEventName.setVariable.rawValue:
//                contextString = mutableEvent.v ?? ""

        case NIDEventName.customTap.rawValue:
            contextString = "xy=\(touchesString) tg=\(tgString) attrs=[\(attrsString)]"
        case NIDEventName.customDoubleTap.rawValue:
            contextString = "xy=\(touchesString) tg=\(tgString) attrs=[\(attrsString)]"
        case NIDEventName.customLongPress.rawValue:
            contextString = "xy=\(touchesString) tg=\(tgString) attrs=[\(attrsString)]"

        case NIDEventName.customTouchStart.rawValue:
            contextString = "xy=\(touchesString) tg=\(tgString) attrs=[\(attrsString)]"
        case NIDEventName.customTouchEnd.rawValue:
            contextString = "xy=\(touchesString) tg=\(tgString) attrs=[\(attrsString)]"

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

        default:
            contextString = ""
    }

    NIDDebugPrint(tag: "NID Event:", "\(mutableEvent.type) - \(mutableEvent.tgs ?? "NO_TARGET") - \(contextString)")
}

func NIDPrintLog(_ strings: Any...) {
    if NeuroID.isStopped() {
        return
    }
    if NeuroID.logVisible {
        Swift.print(strings)
    }
}

func NIDDebugPrint(tag: String = "\(Constants.debugTag.rawValue)", _ strings: Any...) {
    if NeuroID.isStopped() || NeuroID.getEnvironment() != "TEST" {
        return
    }
    if NeuroID.logVisible {
        Swift.print("\(tag) \(strings)")
    }
}
