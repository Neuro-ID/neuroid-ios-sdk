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

    static func startSession(
        _ sessionID: String? = nil,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) -> SessionStartResult {
        if !NeuroID.verifyClientKeyExists() {
            let res = SessionStartResult(false, "")

            completion(res)

            // this is now inaccurate but keeping for backwards compatibility
            return res
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
            let res = SessionStartResult(false, "")

            completion(res)

            // this is now inaccurate but keeping for backwards compatibility
            return res
        }

        // Use config cache or if first time, retrieve from server
        configService.updateConfigOptions {
            NeuroID.setupSession {
                #if DEBUG
                if NSClassFromString("XCTest") == nil {
                    resumeCollection()
                }
                #else
                resumeCollection()
                #endif
            }

            completion(SessionStartResult(true, finalSessionID))
        }

        // this is now inaccurate but keeping for backwards compatibility
        return SessionStartResult(true, finalSessionID)
    }

    static func pauseCollection() {
        pauseCollection(flushEventQueue: true)
    }

    static func resumeCollection() {
        // Don't allow resume to be called if SDK has not been started
        if NeuroID.userID.isEmptyOrNil, !NeuroID.isSDKStarted {
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

    /*
      Function to allow multiple use cases/flows within a single application
      Can be used as the original starting function and then use continuously
       throughout the rest of the session
      i.e. start/startSession/startAppFlow -> startAppFlow("site2") -> stop/stopSession
     */
    static func startAppFlow(
        siteID: String,
        userID: String? = nil,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        if !NeuroID.verifyClientKeyExists() || !NeuroID.validateSiteID(siteID) {
            let res = SessionStartResult(false, "")

            completion(res)
        }

        // if the session is being sampled we should send, else we don't want those events anyways
        if NeuroID._isSessionSampled {
            // immediately flush events before anything else
            groupAndPOST(forceSend: NeuroID._isSessionSampled)
        } else {
            // if not sampled clear any events that might have slipped through
            _ = DataStore.getAndRemoveAllEvents()
        }

        // // Use config cache or if first time, retrieve from server
        configService.updateConfigOptions(siteID: siteID) {
            var startStatus: SessionStartResult

            // The following events have to happen for either
            //  an existing session that begins a new flow OR
            //  a new session with a new flow
            // 1. Determine if flow should be sampled
            // 2. CREATE_SESSION and MOBILE_METADATA events captured
            // 3. Capture ADV (based on global config and lib installed)

            if !NeuroID._isSDKStarted {
                // if userID passed then startSession should be used
                if userID != nil {
                    startStatus = NeuroID.startSession(userID)
                } else {
                    let started = NeuroID.start()
                    startStatus = SessionStartResult(started, NeuroID.getUserID())
                }

                if !startStatus.started {
                    completion(startStatus)
                    return
                }

            } else {
                NeuroID.determineIsSessionSampled()

                // capture CREATE_SESSION and METADATA events for new flow
                saveEventToLocalDataStore(createNIDSessionEvent())
                captureMobileMetadata()

                checkThenCaptureAdvancedDevice()

                startStatus = SessionStartResult(true, NeuroID.getUserID())
            }

            NeuroID.linkedSiteID = siteID

            // Add the SET_LINKED_SITE event for MIHR purposes
            //  this event is ignore by the collector service
            let setLinkedSiteIDEvent = NIDEvent(sessionEvent: NIDSessionEventName.setLinkedSite)
            setLinkedSiteIDEvent.v = siteID
            saveEventToLocalDataStore(setLinkedSiteIDEvent)

            completion(startStatus)
        }
    }
}

extension NeuroID {
    /*
      Determine if the session/flow should be sampled (i.e. events captured and sent)
       if not then change the _isSessionSampled var
       this var will be used in the DataStore.cleanAndStoreEvent method
       and will drop events if false
     */
    static func determineIsSessionSampled() {
        if NeuroID.configService.configCache.currentSampleRate >= 100 {
            NeuroID._isSessionSampled = true
            return
        }

        let randomValue = Double.random(in: 0 ..< 100)
        if randomValue < NeuroID.configService.configCache.currentSampleRate {
            NeuroID._isSessionSampled = true
            return
        }

        NeuroID._isSessionSampled = false
    }

    static func createNIDSessionEvent(sessionEvent: NIDSessionEventName = .createSession) -> NIDEvent {
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

    static func clearStoredSessionID() {
        setUserDefaultKey(Constants.storageSessionIDKey.rawValue, value: nil)
    }

    static func createSession() {
        // Since we are creating a new session, clear any existing session ID
        clearStoredSessionID()

        // TODO, return session if already exists
        let event = createNIDSessionEvent()
        saveEventToLocalDataStore(event)

        captureMobileMetadata()
    }

    static func closeSession(skipStop: Bool = false) throws -> NIDEvent {
        if !NeuroID.isSDKStarted {
            throw NIDError.sdkNotStarted
        }

        let closeEvent = NIDEvent(type: NIDEventName.closeSession)
        closeEvent.ct = "SDK_EVENT"
        saveEventToLocalDataStore(closeEvent)

        if skipStop {
            return closeEvent
        }

        _ = NeuroID.stop()
        return closeEvent
    }

    static func captureMobileMetadata() {
        let event = createNIDSessionEvent(sessionEvent: .mobileMetadataIOS)

        event.attrs = [
            Attrs(n: "orientation", v: ParamsCreator.getOrientation()),
            Attrs(n: "isRN", v: "\(isRN)"),
        ]
        saveEventToLocalDataStore(event)
    }

    static func clearSessionVariables() {
        NeuroID.userID = nil
        NeuroID.registeredUserID = ""
        CURRENT_ORIGIN = nil
        CURRENT_ORIGIN_CODE = nil

        NeuroID.linkedSiteID = nil
    }

    static func pauseCollection(flushEventQueue: Bool = false) {
        if flushEventQueue {
            // flush all events immediately before pause
            groupAndPOST(forceSend: true)
        }

        NeuroID._isSDKStarted = false
        NeuroID.sendCollectionWorkItem?.cancel()
        NeuroID.sendCollectionWorkItem = nil
    }

    static func setupSession(customFunctionality: () -> Void = {}) {
        NeuroID.determineIsSessionSampled()
        NeuroID.createListeners()

        NeuroID._isSDKStarted = true

        NeuroID.callObserver?.startListeningToCallStatus()

        NeuroID.startIntegrationHealthCheck()

        NeuroID.createSession()
        swizzle()

        // custom functionality = the different timer starts (start vs. startSession)
        //  this will be refactored once we bring start/startSession in alignment
        customFunctionality()

        // save beginSession events to MIHR file
        saveIntegrationHealthEvents()

        let queuedEvents = DataStore.getAndRemoveAllQueuedEvents()
        for event in queuedEvents {
            DataStore.insertEvent(screen: "", event: event)
        }

        checkThenCaptureAdvancedDevice()
    }
}
