//
//  NIDSession.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation
import UIKit

public struct SessionStartResult {
    public let started: Bool
    public let sessionID: String

    init(_ started: Bool, _ sessionID: String) {
        self.started = started
        self.sessionID = sessionID
    }
}

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
        CURRENT_ORIGIN = nil
        CURRENT_ORIGIN_CODE = nil
    }

    static func startSession(_ sessionID: String? = nil) -> SessionStartResult {
        if NeuroID.clientKey == nil || NeuroID.clientKey == "" {
            NIDLog.e("Missing Client Key - please call configure prior to calling start")
            return SessionStartResult(false, "")
        }

        // stop existing session if one is open
        if NeuroID.userID != nil || NeuroID.isSDKStarted {
            _ = stopSession()
        }

        // If sessionID is nil, set origin as NID here
        if sessionID == nil {
            NeuroID.CURRENT_ORIGIN = SessionOrigin.NID_ORIGIN_NID_SET.rawValue
            NeuroID.CURRENT_ORIGIN_CODE = SessionOrigin.NID_ORIGIN_CODE_NID.rawValue
        }

        let finalSessionID = sessionID ?? ParamsCreator.generateID()
        if !setUserID(finalSessionID) {
            return SessionStartResult(false, "")
        }

        NeuroID._isSDKStarted = true
        
        NeuroID.callObserver?.startListeningToCallStatus()
        
        startIntegrationHealthCheck()

        checkThenCaptureAdvancedDevice()
        
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

        return SessionStartResult(true, finalSessionID)
    }

    static func pauseCollection() {
        pauseCollection(flushEventQueue: true)
    }

    internal static func pauseCollection(flushEventQueue: Bool = false) {
        if flushEventQueue {
            // flush all events immediately before pause
            groupAndPOST()
        }

        NeuroID._isSDKStarted = false
        NeuroID.sendCollectionWorkItem?.cancel()
        NeuroID.sendCollectionWorkItem = nil
    }

    static func resumeCollection() {
        // Don't allow resume to be called if SDK has not been started
        if (NeuroID.userID.isEmptyOrNil && !NeuroID.isSDKStarted) {
            return
        }
        NeuroID._isSDKStarted = true
        let workItem = NeuroID.createCollectionWorkItem()
        NeuroID.sendCollectionWorkItem = workItem
        initCollectionTimer()
        initGyroAccelCollectionTimer()
    }

    static func stopSession() -> Bool {
        let closeEvent = NIDEvent(type: NIDEventName.closeSession)
        closeEvent.ct = "SDK_EVENT"
        saveEventToLocalDataStore(closeEvent)

        pauseCollection()

        clearSessionVariables()
        
        // Stop listening to changes in call status
        NeuroID.callObserver?.stopListeningToCallStatus()

        return true
    }
}
