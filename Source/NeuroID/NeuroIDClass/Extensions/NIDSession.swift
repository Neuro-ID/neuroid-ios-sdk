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

    static func startSession(
        _ sessionID: String? = nil,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        NeuroID.startSession(siteID: nil, sessionID: sessionID, completion: completion)
    }

    static func pauseCollection() {
        saveEventToLocalDataStore(
            NIDEvent(type: .log, level: "INFO", m: "pause collection attempt")
        )
        pauseCollection(flushEventQueue: true)
    }

    static func resumeCollection() {
        saveEventToLocalDataStore(
            NIDEvent(type: .log, level: "INFO", m: "resume collection attempt")
        )
        // Don't allow resume to be called if SDK has not been started
        if NeuroID.sessionID.isEmptyOrNil, !NeuroID.isSDKStarted {
            return
        }
        NeuroID._isSDKStarted = true
        let workItem = NeuroID.createCollectionWorkItem()
        NeuroID.sendCollectionWorkItem = workItem
        initCollectionTimer()
        initGyroAccelCollectionTimer()
    }

    static func stopSession() -> Bool {
        saveEventToLocalDataStore(
            NIDEvent(type: .log, level: "INFO", m: "Stop session attempt")
        )
        
        saveEventToLocalDataStore(
            NIDEvent(type: .closeSession, ct: "SDK_EVENT")
        )
        
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
        sessionID: String? = nil,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        
        _ = NeuroID.identifierService.logScrubbedIdentityAttempt(
                 identifier: sessionID ?? "null",
                 message: "StartAppFlow attempt with siteID: \(siteID), sessionID:"
            )


        if !NeuroID.verifyClientKeyExists() || !NeuroID.validationService.validateSiteID(siteID) {
            let res = SessionStartResult(false, "")

            NeuroID.linkedSiteID = nil
            
            saveEventToLocalDataStore(
                NIDEvent(
                    type: .log,
                    level: "ERROR",
                    m: "Failed to set invalid Linked Site \(siteID)"
                )
            )

            completion(res)
            return
        }

        // Clear or Send events based on sample rate
        NeuroID.clearSendOldFlowEvents {
            // The following events have to happen for either
            //  an existing session that begins a new flow OR
            //  a new session with a new flow
            // 1. Determine if flow should be sampled
            // 2. CREATE_SESSION and MOBILE_METADATA events captured
            // 3. Capture ADV (based on global config and lib installed)

            // If SDK is already started, update sampleStatus and continue
            if NeuroID.isSDKStarted {
                NeuroID.samplingService.updateIsSampledStatus(siteID: siteID)

                // capture CREATE_SESSION and METADATA events for new flow
                saveEventToLocalDataStore(createNIDSessionEvent())
                captureMobileMetadata()

                captureAdvancedDevice()

                NeuroID.addLinkedSiteID(siteID)
                completion(
                    SessionStartResult(true, NeuroID.getSessionID())
                )

            } else {
                // If the SDK is not started we have to start it first
                //  (which will get the config using passed siteID)

                // if sessionID passed then startSession should be used
                if sessionID != nil {
                    NeuroID.startSession(siteID: siteID, sessionID: sessionID) { startStatus in
                        if !startStatus.started {
                            completion(startStatus)
                            
                            saveEventToDataStore(
                                NIDEvent(
                                    type: .log,
                                    level: "INFO",
                                    m: "Failed to startAppFlow with inner startSession command"
                                )
                            )
                            return
                        }
                        NeuroID.addLinkedSiteID(siteID)
                        completion(startStatus)
                    }
                } else {
                    NeuroID.start(siteID: siteID) { started in
                        if !started {
                            completion(
                                SessionStartResult(started, NeuroID.getSessionID())
                            )
                            
                            saveEventToDataStore(
                                NIDEvent(
                                    type: .log,
                                    level: "INFO",
                                    m: "Failed to startAppFlow with inner start command"
                                )
                            )
                            return
                        }
                        
                        NeuroID.addLinkedSiteID(siteID)
                        completion(
                            SessionStartResult(started, NeuroID.getSessionID())
                        )
                    }
                }
            }
        }
    }
}

extension NeuroID {
    static func createNIDSessionEvent(
        sessionEvent: NIDSessionEventName = .createSession
    ) -> NIDEvent {
        return NIDEvent(
            session: sessionEvent,
            f: NeuroID.getClientKey(),
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

    static func createSession() {
        saveEventToLocalDataStore(
            createNIDSessionEvent()
        )

        captureMobileMetadata()
    }

    static func closeSession(skipStop: Bool = false) throws -> NIDEvent {
        saveEventToDataStore(
            NIDEvent(type: .log, level: "INFO", m: "Close session attempt")
        )

        if !NeuroID.isSDKStarted {
            saveQueuedEventToLocalDataStore(
                NIDEvent(type: .log, level: "ERROR", m: "Close attempt failed since SDK is not started")
            )
            throw NIDError.sdkNotStarted
        }

        let closeEvent = NIDEvent(type: .closeSession, ct: "SDK_EVENT")
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

        captureApplicationMetaData()
    }

    static func clearSessionVariables() {
        NeuroID.sessionID = nil
        NeuroID.registeredUserID = ""

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

    /**
     Function to setup all the required events and listeners for the beginning of a session
     - Will update sampling status
     - Wll create and trigger listeners
     - Will start swizzling
     - Will move queued events into main queue
     - Will make call to check/capture ADV event
     */
    static func setupSession(
        siteID: String?,
        customFunctionality: @escaping () -> Void = {},
        completion: @escaping () -> Void = {}
    ) {
        // Use config cache or if first time, retrieve from server
       configService.retrieveOrRefreshCache()

        NeuroID.samplingService.updateIsSampledStatus(siteID: siteID)

        NeuroID._isSDKStarted = true

        NeuroID.setupListeners()

        NeuroID.createSession()
        swizzle()

        // custom functionality = the different timer starts (start vs. startSession)
        //  this will be refactored once we bring start/startSession in alignment
        customFunctionality()

        moveQueuedEventsToDataStore()
       
        captureAdvancedDevice()

        completion()
    }

    // Internal implementation that allows a siteID
    static func start(
        siteID: String?,
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        saveEventToDataStore(
            NIDEvent(type: .log, level: "INFO", m: "Start attempt with siteID: \(siteID ?? ""))")
        )

        if !NeuroID.verifyClientKeyExists() {
            completion(false)
            return
        }

        // Setup Session with old start timer logic
        // TO-DO - Refactor to behave like startSession
        NeuroID.setupSession(
            siteID: siteID,
            customFunctionality: {
                #if DEBUG
                if NSClassFromString("XCTest") == nil {
                    initTimer()
                }
                #else
                initTimer()
                #endif
                initGyroAccelCollectionTimer()
        }) {
            completion(true)
        }
    }

    // Internal implementation that allows a siteID
    static func startSession(
        siteID: String?,
        sessionID: String? = nil,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        if !NeuroID.verifyClientKeyExists() {
            let res = SessionStartResult(false, "")

            completion(res)
            return
        }

        // stop existing session if one is open
        if NeuroID.sessionID != nil || NeuroID.isSDKStarted {
            _ = stopSession()
        }

        // If sessionID is nil, set origin as NID here
        let userGenerated = sessionID != nil

        let finalSessionID = sessionID ?? ParamsCreator.generateID()
        
        _ = NeuroID.identifierService.logScrubbedIdentityAttempt(
                 identifier: finalSessionID,
                 message: "StartSession attempt with siteID: \(siteID ?? ""), sessionID:"
            )
        
        let validSessionID = NeuroID.identifierService.setSessionID(
                 finalSessionID,
                 userGenerated
             )

        if !validSessionID {
            let res = SessionStartResult(false, "")

            completion(res)
            return
        }

        NeuroID.setupSession(
            siteID: siteID,
            customFunctionality: {
                #if DEBUG
                if NSClassFromString("XCTest") == nil {
                    resumeCollection()
                }
                #else
                resumeCollection()
                #endif
        }) {
            completion(SessionStartResult(true, finalSessionID))
        }
    }

    static func clearSendOldFlowEvents(completion: @escaping () -> Void = {}) {
        // if the session is being sampled we should send, else we don't want those events anyways
        if NeuroID.samplingService.isSessionFlowSampled {
            // immediately flush events before anything else
            groupAndPOST(forceSend: NeuroID.samplingService.isSessionFlowSampled) {
                completion()
            }
            return
        } else {
            // if not sampled clear any events that might have slipped through
            _ = NeuroID.datastore.getAndRemoveAllEvents()

            completion()

            return
        }
    }
}
