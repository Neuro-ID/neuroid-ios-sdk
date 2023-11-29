//
//  NIDSession.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation
import UIKit

public extension NeuroID {
    internal static func createNIDSessionEvent(sessionEvent: NIDSessionEventName = .createSession) -> NIDEvent {
        return NIDEvent(
            session: sessionEvent,
            f: NeuroID.getClientKey(),
            sid: NeuroID.getSessionID(),
            lsid: nil,
            cid: NeuroID.getClientID(),
            did: ParamsCreator.getDeviceId(),
            loc: ParamsCreator.getLocale(),
            ua: ParamsCreator.getUserAgent(),
            tzo: ParamsCreator.getTimezone(),
            lng: ParamsCreator.getLanguage(),
            p: ParamsCreator.getPlatform(),
            dnt: false,
            tch: ParamsCreator.getTouch(),
            pageTag: NeuroID.getScreenName(),
            ns: ParamsCreator.getCommandQueueNamespace(),
            jsv: NeuroID.getSDKVersion(),
            sh: UIScreen.main.bounds.height,
            sw: UIScreen.main.bounds.width,
            metadata: NIDMetadata()
        )
    }

    // Sessions are created under conditions:
    // Launch of application
    // If user idles for > 30 min
    static func getSessionID() -> String {
        // We don't do anything with this?
        let _ = Constants.storageSessionExpiredKey.rawValue

        let sidKeyName = Constants.storageSessionIDKey.rawValue

        let sid = getUserDefaultKeyString(sidKeyName)

        // TODO: Expire sesions
        if let sidValue = sid {
            return sidValue
        }

        let id = ParamsCreator.generateID()
        setUserDefaultKey(sidKeyName, value: id)

        NIDLog.i("\(Constants.sessionTag.rawValue)", id)
        return id
    }

    internal static func clearStoredSessionID() {
        setUserDefaultKey(Constants.storageSessionIDKey.rawValue, value: nil)
    }

    internal static func createSession() {
        // Since we are creating a new session, clear any existing session ID
        clearStoredSessionID()

        // TODO, return session if already exists
        let event = createNIDSessionEvent()
        saveEventToLocalDataStore(event)

        captureMobileMetadata()
    }

    internal static func closeSession(skipStop: Bool = false) throws -> NIDEvent {
        if !NeuroID.isSDKStarted {
            throw NIDError.sdkNotStarted
        }

        let closeEvent = NIDEvent(type: NIDEventName.closeSession)
        closeEvent.ct = "SDK_EVENT"
        saveEventToLocalDataStore(closeEvent)

        if skipStop {
            return closeEvent
        }

        NeuroID.stop()
        return closeEvent
    }

    internal static func captureMobileMetadata() {
        let event = createNIDSessionEvent(sessionEvent: .mobileMetadataIOS)

        event.attrs = [
            Attrs(n: "orientation", v: ParamsCreator.getOrientation()),
            Attrs(n: "isRN", v: "\(isRN)"),
        ]
        saveEventToLocalDataStore(event)
    }

    internal static func clearSessionVariables() {
        NeuroID.userID = nil
        NeuroID.registeredUserID = ""
    }

    static func startSession(_ sessionID: String? = nil) -> (Bool, String) {
        if NeuroID.clientKey == nil || NeuroID.clientKey == "" {
            NIDLog.e("Missing Client Key - please call configure prior to calling start")
            return (false, "")
        }

        // stop existing session if one is open
        if NeuroID.userID != nil || NeuroID.isSDKStarted {
            _ = stopSession()
        }

        let finalSessionID = sessionID ?? ParamsCreator.generateID()
        if !setUserID(finalSessionID) {
            return (false, "")
        }

        NeuroID._isSDKStarted = true
        startIntegrationHealthCheck()

        createSession()
        swizzle()

        #if DEBUG
        if NSClassFromString("XCTest") == nil {
            resumeCollection()
        }
        #else
        resumeCollection()
        #endif

        // save captured health events to file
        saveIntegrationHealthEvents()

        let queuedEvents = DataStore.getAndRemoveAllQueuedEvents()
        queuedEvents.forEach { event in
            DataStore.insertEvent(screen: "", event: event)
        }

        return (true, finalSessionID)
    }

    static func pauseCollection() {
        // flush all events immediately before pause
        groupAndPOST()

        NeuroID._isSDKStarted = false
        NeuroID.sendCollectionWorkItem?.cancel()
        NeuroID.sendCollectionWorkItem = nil
    }

    static func resumeCollection() {
        NeuroID._isSDKStarted = true
        let workItem = NeuroID.createCollectionWorkItem()
        NeuroID.sendCollectionWorkItem = workItem
        initCollectionTimer()
    }

    static func stopSession() -> Bool {
        let closeEvent = NIDEvent(type: NIDEventName.closeSession)
        closeEvent.ct = "SDK_EVENT"
        saveEventToLocalDataStore(closeEvent)

        pauseCollection()

        clearSessionVariables()

        return true
    }
}
