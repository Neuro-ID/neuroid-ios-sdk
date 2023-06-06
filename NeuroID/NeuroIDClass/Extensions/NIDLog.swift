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
