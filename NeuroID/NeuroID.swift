//
//  NeuroID.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Alamofire
import CommonCrypto
import Foundation
import ObjectiveC
import os
import SwiftUI
import UIKit
import WebKit

// MARK: - Neuro ID Class

public enum NeuroID {
    fileprivate static var sequenceId = 1
    internal static var clientKey: String?
    internal static var siteId: String?
    fileprivate static let sessionId: String = ParamsCreator.getSessionID()
    public static var clientId: String?
    public static var userId: String?
    public static var registeredTargets = [String]()
    private static let SEND_INTERVAL: Double = 5
    internal static var trackers = [String: NeuroIDTracker]()
    internal static var secretViews = [UIView]()
    internal static let showDebugLog = false
    fileprivate static var _currentScreenName: String?

    static var excludedViewsTestIDs = [String]()
    private static let lock = NSLock()

    private static var environment: String = "TEST"
    private static var currentScreenName: String? {
        get { lock.withCriticalSection { _currentScreenName } }
        set { lock.withCriticalSection { _currentScreenName = newValue } }
    }

    fileprivate static let localStorageNIDStopAll = "nid_stop_all"

    /// Turn on/off printing the SDK log to your console
    public static var logVisible = true
    public static var activeView: UIView?
    public static var collectorURLFromConfig: String?
    public static var isSDKStarted = false
    public static var observingInputs = false

    // MARK: - Setup

    /// 1. Configure the SDK
    /// 2. Setup silent running loop
    /// 3. Send cached events from DB every `SEND_INTERVAL`
    public static func configure(clientKey: String) {
        if NeuroID.clientKey != nil {
            print("NeuroID Error: You already configured the SDK")
        }

        // Call clear session here
        clearSession()

        NeuroID.clientKey = clientKey
        let key = "nid_key"
        let defaults = UserDefaults.standard
        defaults.set(clientKey, forKey: key)

        // Reset tab id on configure
        UserDefaults.standard.set(nil, forKey: "nid_tid")

        NeuroID.createSession()
    }

    // Allow for configuring of collector endpoint (useful for testing before MSA is signed)
    public static func configure(clientKey: String, collectorEndPoint: String) {
        collectorURLFromConfig = collectorEndPoint
        configure(clientKey: clientKey)
    }

    /**
     Enable or disable the NeuroID debug logging
     */
    public static func enableLogging(_ value: Bool) {
        logVisible = value
    }

    /**
     Public user facing getClientID function
     */
    public static func getClientID() -> String {
        return ParamsCreator.getClientId()
    }

    public static func setEnvironmentProduction(_ value: Bool) {
        if value {
            environment = "LIVE"
        } else {
            environment = "TEST"
        }
    }

    public static func setSiteId(siteId: String) {
        self.siteId = siteId
    }

    public static func getEnvironment() -> String {
        return environment
    }

    public static func stop() {
        NIDPrintLog("NeuroID Stopped")
        UserDefaults.standard.set(true, forKey: localStorageNIDStopAll)
    }

    public static func excludeViewByTestID(excludedView: String) {
        NIDPrintLog("Exclude view called - \(excludedView)")
        NeuroID.excludedViewsTestIDs.append(excludedView)
    }

    /**
     Set screen name. We ensure that this is a URL valid name by replacing non alphanumber chars with underscore
     */
    public static func setScreenName(screen: String) {
        if let urlEncode = screen.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            currentScreenName = urlEncode
        } else {
            logError(content: "Invalid Screenname for NeuroID. \(screen) can't be encode")
        }
    }

    public static func getScreenName() -> String? {
        if !currentScreenName.isEmptyOrNil {
            return "\(currentScreenName ?? "")"
        }
        return currentScreenName
    }

    public static func clearSession() {
        UserDefaults.standard.set(nil, forKey: "nid_sid")
        UserDefaults.standard.set(nil, forKey: "nid_cid")
    }

    public static func getSessionID() -> String? {
        return UserDefaults.standard.string(forKey: "nid_sid")
    }

    static func createSession() {
        // Since we are creating a new session, clear any existing session ID
        NeuroID.clearSession()
        // TODO, return session if already exists
        var event = NIDEvent(session: .createSession, f: ParamsCreator.getClientKey(), sid: ParamsCreator.getSessionID(), lsid: nil, cid: ParamsCreator.getClientId(), did: ParamsCreator.getDeviceId(), loc: ParamsCreator.getLocale(), ua: ParamsCreator.getUserAgent(), tzo: ParamsCreator.getTimezone(), lng: ParamsCreator.getLanguage(), p: ParamsCreator.getPlatform(), dnt: false, tch: ParamsCreator.getTouch(), pageTag: NeuroID.getScreenName(), ns: ParamsCreator.getCommandQueueNamespace(), jsv: ParamsCreator.getSDKVersion())
        event.sh = UIScreen.main.bounds.height
        event.sw = UIScreen.main.bounds.width
        event.metadata = NIDMetadata()
        saveEventToLocalDataStore(event)
    }

    public static func closeSession() throws -> NIDEvent {
        if !NeuroID.isSDKStarted {
            throw NIDError.sdkNotStarted
        }
        var closeEvent = NIDEvent(type: NIDEventName.closeSession)
        closeEvent.ct = "SDK_EVENT"
        saveEventToLocalDataStore(closeEvent)
        NeuroID.stop()
        return closeEvent
    }

    // When start is called, enable swizzling, as well as dispatch queue to send to API
    public static func start() {
        NeuroID.isSDKStarted = true
        UserDefaults.standard.set(false, forKey: localStorageNIDStopAll)
        swizzle()

        if ProcessInfo.processInfo.environment["debugJSON"] == "true" {
            let filemgr = FileManager.default
            let path = filemgr.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("nidJSONPOSTFormat.txt")
            NIDPrintLog("DEBUG PATH \(path.absoluteString)")
        }

        #if DEBUG
        if NSClassFromString("XCTest") == nil {
            initTimer()
        }
        #else
        initTimer()
        #endif
    }

    public static func isStopped() -> Bool {
        let key = UserDefaults.standard.bool(forKey: localStorageNIDStopAll)
        if key {
            return true
        }
        return false
    }

    /**
        Form Submit, Sccuess & Failure
     */
    public static func formSubmit() -> NIDEvent {
        let submitEvent = NIDEvent(type: NIDEventName.applicationSubmit)
        saveEventToLocalDataStore(submitEvent)
        return submitEvent
    }

    public static func formSubmitFailure() -> NIDEvent {
        let submitEvent = NIDEvent(type: NIDEventName.applicationSubmitFailure)
        saveEventToLocalDataStore(submitEvent)
        return submitEvent
    }

    public static func formSubmitSuccess() -> NIDEvent {
        let submitEvent = NIDEvent(type: NIDEventName.applicationSubmitSuccess)
        saveEventToLocalDataStore(submitEvent)
        return submitEvent
    }

    /**
     Set a custom variable with a key and value.
        - Parameters:
            - key: The string value of the variable key
            - v: The string value of variable
        - Returns: An `NIDEvent` object of type `SET_VARIABLE`

     */
    public static func setCustomVariable(key: String, v: String) -> NIDEvent {
        var setCustomVariable = NIDEvent(type: NIDSessionEventName.setVariable, key: key, v: v)
        let myKeys: [String] = trackers.map { String($0.key) }
        // Set the screen to the last active view
        setCustomVariable.url = myKeys.last
        // If we don't have a valid URL, that means this was called before any views were tracked. Use "AppDelegate" as default
        if setCustomVariable.url == nil || setCustomVariable.url!.isEmpty {
            setCustomVariable.url = "AppDelegate"
        }
        saveEventToLocalDataStore(setCustomVariable)
        return setCustomVariable
    }

    public static func getCollectionEndpointURL() -> String {
        //  Prod URL
        //    return collectorURLFromConfig ?? "https://api.neuro-id.com/v3/c"
        //    return "https://rc.api.usw2-prod1.nidops.net"
        //    return "http://localhost:8080"
        //    return "https://api.usw2-dev1.nidops.net";
        //
        //    #if DEBUG
        //    return collectorURLFromConfig ?? "https://receiver.neuro-dev.com/c"
        //    #elseif STAGING
        //    return collectorURLFromConfig ?? "https://receiver.neuro-dev.com/c"
        //    #elseif RELEASE
        //    return  "https://api.neuro-id.com/v3/c"
        //    #endif
        return "https://receiver.neuroid.cloud/c"
    }

    static func getClientKeyFromLocalStorage() -> String {
        let keyName = "nid_key"
        let defaults = UserDefaults.standard
        let key = defaults.string(forKey: keyName)
        return key ?? ""
    }

    private static func swizzle() {
        UIViewController.startSwizzling()
        UITextField.startSwizzling()
        UITextView.startSwizzling()
        UINavigationController.swizzleNavigation()
        UITableView.tableviewSwizzle()
//        UIButton.startSwizzling()
    }

    private static func initTimer() {
        // Send up the first payload, and then setup a repeating timer
//        self.send()
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + SEND_INTERVAL) {
            self.send()
            self.initTimer()
        }
    }

    /**
     Publically exposed just for testing. This should not be any reason to call this directly.
     */
    public static func send() {
        DispatchQueue.global(qos: .utility).async {
            if !NeuroID.isStopped() {
                groupAndPOST()
            }
        }
    }

    /** Public API for manually registering a target. This should only be used when automatic fails. */
    public static func manuallyRegisterTarget(view: UIView) {
        let screenName = view.id
        let guid = UUID().uuidString
        NIDPrintLog("Registering single view: \(screenName)")
        NeuroIDTracker.registerSingleView(v: view, screenName: screenName, guid: guid)
        let childViews = view.subviewsRecursive()
        for _view in childViews {
            NIDPrintLog("Registering subview Parent: \(screenName) Child: \(_view)")
            NeuroIDTracker.registerSingleView(v: _view, screenName: screenName, guid: guid)
        }
    }

    /** React Native API for manual registration */
    public static func manuallyRegisterRNTarget(id: String, className: String, screenName: String, placeHolder: String) -> NIDEvent {
        let guid = UUID().uuidString
        let fullViewString = NeuroIDTracker.getFullViewlURLPath(currView: nil, screenName: screenName)
        var nidEvent = NIDEvent(eventName: NIDEventName.registerTarget, tgs: id, en: id, etn: "INPUT", et: "\(className)", ec: screenName, v: "S~C~~\(placeHolder.count)", url: screenName)
        nidEvent.hv = placeHolder.sha256().prefix(8).string
        let attrVal = Attrs(n: "guid", v: guid)
        // Screen hierarchy
        let shVal = Attrs(n: "screenHierarchy", v: fullViewString)
        let guidValue = Attr(n: "guid", v: guid)
        let attrValue = Attr(n: "screenHierarchy", v: fullViewString)
        nidEvent.tg = ["attr": TargetValue.attr([attrValue, guidValue])]
        nidEvent.attrs = [attrVal, shVal]
        NeuroID.saveEventToLocalDataStore(nidEvent)
        return nidEvent
    }

    /**
     Publically exposed just for testing. This should not be any reason to call this directly.
     */
    public static func groupAndPOST() {
        if NeuroID.isStopped() {
            return
        }
        let dataStoreEvents = DataStore.getAllEvents()

        let backupCopy = dataStoreEvents
        // Clean event queue immediately after fetching
        DataStore.removeSentEvents()
        if dataStoreEvents.isEmpty {
            return
        }

        /** Just send all the evnets */
        let cleanEvents = dataStoreEvents.map { nidevent -> NIDEvent in
            var newEvent = nidevent
            // Only send url on register target and create session.
            if nidevent.type != NIDEventName.registerTarget.rawValue, nidevent.type != "CREATE_SESSION" {
                newEvent.url = nil
            }
            return newEvent
        }

        post(events: cleanEvents, screen: (getScreenName() ?? backupCopy[0].url) ?? "unnamed_screen", onSuccess: { _ in
            logInfo(category: "APICall", content: "Sending successfully")
            // send success -> delete

        }, onFailure: { error in
            logError(category: "APICall", content: String(describing: error))
        })
    }

    /// Direct send to API to create session
    /// Regularly send in loop
    fileprivate static func post(events: [NIDEvent],
                                 screen: String,
                                 onSuccess: @escaping (Any) -> Void,
                                 onFailure: @escaping
                                 (Error) -> Void)
    {
        guard let url = URL(string: NeuroID.getCollectionEndpointURL()) else {
            logError(content: "NeuroID base URL found")
            return
        }

        let tabId = ParamsCreator.getTabId()

        let randomString = UUID().uuidString
        let pageid = randomString.replacingOccurrences(of: "-", with: "").prefix(12)

        let neuroHTTPRequest = NeuroHTTPRequest(clientId: ParamsCreator.getClientId(), environment: NeuroID.getEnvironment(), sdkVersion: ParamsCreator.getSDKVersion(), pageTag: NeuroID.getScreenName() ?? "UNKNOWN", responseId: ParamsCreator.generateUniqueHexId(), siteId: NeuroID.siteId ?? "", userId: ParamsCreator.getUserID() ?? "", jsonEvents: events, tabId: "\(tabId)", pageId: "\(pageid)", url: "ios://\(NeuroID.getScreenName() ?? "")")

        if ProcessInfo.processInfo.environment["debugJSON"] == "true" {
            saveDebugJSON(events: "******************** New POST to NID Collector")
//            saveDebugJSON(events: dataString)
//            saveDebugJSON(events: jsonEvents):
            saveDebugJSON(events: "******************** END")
        }

        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "site_key": ParamsCreator.getClientKey(),
            "authority": "receiver.neuroid.cloud",
        ]

        AF.request(url, method: .post, parameters: neuroHTTPRequest, encoder: JSONParameterEncoder.default, headers: headers).responseData { response in
            // 204 invalid, 200 valid
            NIDPrintLog("NID Response \(response.response?.statusCode ?? 000)")
            NIDPrintLog("NID Payload: \(neuroHTTPRequest)")
            switch response.result {
            case .success:
                NIDPrintLog("Neuro-ID post to API Successfull")
            case let .failure(error):
                NIDPrintLog("Neuro-ID FAIL to post API")
                logError(content: "Neuro-ID post Error: \(error)")
            }
        }

        // Output post data to terminal if debug
        if ProcessInfo.processInfo.environment["debugJSON"] == "true" {
            do {
                let data = try JSONEncoder().encode(neuroHTTPRequest)
                let str = String(data: data, encoding: .utf8)
                NIDPrintLog(str as Any)
            } catch {}
        }
    }

    public static func setUserID(_ userId: String) {
        UserDefaults.standard.set(userId, forKey: "nid_user_id")
        let setUserEvent = NIDEvent(session: NIDSessionEventName.setUserId, userId: userId)
        NeuroID.userId = userId
        NIDPrintLog("NID userID = <\(userId)>")
        saveEventToLocalDataStore(setUserEvent)
    }

    public static func getUserID() -> String {
        let userId = UserDefaults.standard.string(forKey: "nid_user_id")
        return NeuroID.userId ?? userId ?? ""
    }

    public static func logInfo(category: String = "default", content: Any...) {
        osLog(category: category, content: content, type: .info)
    }

    public static func logError(category: String = "default", content: Any...) {
        osLog(category: category, content: content, type: .error)
    }

    public static func logFault(category: String = "default", content: Any...) {
        osLog(category: category, content: content, type: .fault)
    }

    public static func logDebug(category: String = "default", content: Any...) {
        osLog(category: category, content: content, type: .debug)
    }

    public static func logDefault(category: String = "default", content: Any...) {
        osLog(category: category, content: content, type: .default)
    }

    private static func osLog(category: String = "default", content: Any..., type: OSLogType) {
        Log.log(category: category, contents: content, type: .info)
    }

    public static func saveEventToLocalDataStore(_ event: NIDEvent) {
        DataStore.insertEvent(screen: event.type, event: event)
    }

    /**
     Save the params being sent to POST to collector endpoint to a local file
     */
    private static func saveDebugJSON(events: String) {
        let jsonStringNIDEvents = "\(events)".data(using: .utf8)!
        do {
            let filemgr = FileManager.default
            let path = filemgr.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("nidJSONPOSTFormat.txt")
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

// MARK: - NeuroID for testing functions

extension NeuroID {
    static func cleanUpForTesting() {
        clientKey = nil
    }

    /// Get the current SDK versión from bundle
    /// - Returns: String with the version format
    public static func getSDKVersion() -> String? {
        return ParamsCreator.getSDKVersion()
    }
}

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
