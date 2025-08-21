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
        NeuroID.shared.saveEventToLocalDataStore(
            NIDEvent.createInfoLogEvent("pause collection attempt")
        )
        pauseCollection(flushEventQueue: true)
    }

    static func resumeCollection() {
        NeuroID.shared.saveEventToLocalDataStore(
            NIDEvent.createInfoLogEvent("resume collection attempt")
        )
        // Don't allow resume to be called if SDK has not been started
        if NeuroID.shared.identifierService.sessionID.isEmptyOrNil,
           !NeuroID.shared.isSDKStarted
        {
            return
        }
        NeuroID.shared._isSDKStarted = true
        NeuroID.shared.sendCollectionEventsJob.start()
        NeuroID.shared.collectGyroAccelEventJob.start()
    }

    static func stopSession() -> Bool {
        NeuroID.shared.saveEventToLocalDataStore(
            NIDEvent.createInfoLogEvent("Stop session attempt")
        )

        NeuroID.shared.saveEventToLocalDataStore(
            NIDEvent(type: .closeSession, ct: "SDK_EVENT")
        )

        pauseCollection()

        clearSessionVariables()

        // Stop listening to changes in call status
        NeuroID.shared.callObserver?.stopListeningToCallStatus()

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
        _ = NeuroID.shared.identifierService.logScrubbedIdentityAttempt(
            identifier: sessionID ?? "null",
            message: "StartAppFlow attempt with siteID: \(siteID), sessionID:"
        )

        if !NeuroID.shared.verifyClientKeyExists()
            || !NeuroID.shared.validationService.validateSiteID(siteID)
        {
            let res = SessionStartResult(false, "")

            NeuroID.shared.linkedSiteID = nil

            NeuroID.shared.saveEventToLocalDataStore(
                NIDEvent.createErrorLogEvent(
                    "Failed to set invalid Linked Site \(siteID)"
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
            if NeuroID.shared.isSDKStarted {
                NeuroID.shared.configService.updateIsSampledStatus(siteID: siteID)

                // capture CREATE_SESSION and METADATA events for new flow
                NeuroID.shared.saveEventToLocalDataStore(createNIDSessionEvent())
                captureMobileMetadata()

                captureAdvancedDevice(NeuroID.shared.isAdvancedDevice)

                NeuroID.shared.addLinkedSiteID(siteID)
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

                            NeuroID.shared.saveEventToDataStore(
                                NIDEvent.createInfoLogEvent(
                                    "Failed to startAppFlow with inner startSession command"
                                )
                            )
                            return
                        }
                        NeuroID.shared.addLinkedSiteID(siteID)
                        completion(startStatus)
                    }
                } else {
                    NeuroID.start(siteID: siteID) { started in
                        if !started {
                            completion(
                                SessionStartResult(started, NeuroID.getSessionID())
                            )

                            NeuroID.shared.saveEventToDataStore(
                                NIDEvent.createInfoLogEvent(
                                    "Failed to startAppFlow with inner start command"
                                )
                            )
                            return
                        }

                        NeuroID.shared.addLinkedSiteID(siteID)
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
        sessionEvent: NIDEventName = .createSession
    ) -> NIDEvent {
        return NIDEvent(
            type: sessionEvent,
            f: NeuroID.shared.getClientKey(),
            cid: NeuroID.getClientID(),
            did: ParamsCreator.getDeviceId(),
            loc: ParamsCreator.getLocale(),
            ua: ParamsCreator.getUserAgent(),
            tzo: ParamsCreator.getTimezone(),
            lng: ParamsCreator.getLanguage(),
            p: ParamsCreator.getPlatform(),
            dnt: false,
            tch: ParamsCreator.getTouch(),
            url: NeuroID.getScreenName(),
            ns: ParamsCreator.getCommandQueueNamespace(),
            jsv: NeuroID.getSDKVersion(),
            metadata: NIDMetadata(),
            sh: UIScreen.main.bounds.height,
            sw: UIScreen.main.bounds.width
        )
    }

    static func createSession() {
        NeuroID.shared.configService.updateIsSampledStatus(siteID: NeuroID.shared.linkedSiteID)
        NeuroID.shared.saveEventToLocalDataStore(
            createNIDSessionEvent()
        )

        captureMobileMetadata()
    }

     func closeSession(skipStop: Bool = false) throws -> NIDEvent {
        self.saveEventToDataStore(
            NIDEvent.createInfoLogEvent("Close session attempt")
        )

        if !self.isSDKStarted {
            self.saveQueuedEventToLocalDataStore(
                NIDEvent.createErrorLogEvent("Close attempt failed since SDK is not started")
            )
            throw NIDError.sdkNotStarted
        }

        let closeEvent = NIDEvent(type: .closeSession, ct: "SDK_EVENT")
        self.saveEventToLocalDataStore(closeEvent)

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
            Attrs(n: "isRN", v: "\(NeuroID.shared.isRN)"),
        ]
        NeuroID.shared.saveEventToLocalDataStore(event)

        NeuroID.shared.captureApplicationMetaData()
    }

    static func clearSessionVariables() {
        NeuroID.shared.identifierService.clearIDs()

        NeuroID.shared.linkedSiteID = nil
    }

    static func pauseCollection(flushEventQueue: Bool = false) {
        if flushEventQueue {
            // flush all events immediately before pause
            NeuroID.shared.send(forceSend: true)
        }

        NeuroID.shared._isSDKStarted = false

        NeuroID.shared.sendCollectionEventsJob.cancel()
        NeuroID.shared.collectGyroAccelEventJob.cancel()

        NeuroID.shared.configService.clearSiteIDMap()
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
        NeuroID.shared.configService.retrieveOrRefreshCache()

        NeuroID.shared.configService.updateIsSampledStatus(siteID: siteID)

        NeuroID.shared._isSDKStarted = true

        NeuroID.shared.setupListeners()

        NeuroID.createSession()
        swizzle()

        // custom functionality = the different timer starts (start vs. startSession)
        //  this will be refactored once we bring start/startSession in alignment
        customFunctionality()

        NeuroID.shared.moveQueuedEventsToDataStore()

        captureAdvancedDevice(NeuroID.shared.isAdvancedDevice)

        completion()
    }

    // Internal implementation that allows a siteID
    static func start(
        siteID: String?,
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        NeuroID.shared.saveEventToDataStore(
            NIDEvent.createInfoLogEvent("Start attempt with siteID: \(siteID ?? ""))")
        )

        if !NeuroID.shared.verifyClientKeyExists() {
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
                        NeuroID.shared.sendCollectionEventsJob.start()
                    }
                #else
                    NeuroID.sendCollectionEventsJob.start()
                #endif
                NeuroID.shared.collectGyroAccelEventJob.start()
            }
        ) {
            completion(true)
        }
    }

    // Internal implementation that allows a siteID
    static func startSession(
        siteID: String?,
        sessionID: String? = nil,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        if !NeuroID.shared.verifyClientKeyExists() {
            let res = SessionStartResult(false, "")

            completion(res)
            return
        }

        // stop existing session if one is open
        if !NeuroID.shared.identifierService.sessionID.isEmptyOrNil || NeuroID.shared.isSDKStarted {
            _ = stopSession()
        }

        // If sessionID is nil, set origin as NID here
        let userGenerated = sessionID != nil

        let finalSessionID = sessionID ?? ParamsCreator.generateID()

        _ = NeuroID.shared.identifierService.logScrubbedIdentityAttempt(
            identifier: finalSessionID,
            message: "StartSession attempt with siteID: \(siteID ?? ""), sessionID:"
        )

        let validSessionID = NeuroID.shared.identifierService.setSessionID(
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
            }
        ) {
            completion(SessionStartResult(true, finalSessionID))
        }
    }

    static func clearSendOldFlowEvents(completion: @escaping () -> Void = {}) {
        // if the session is being sampled we should send, else we don't want those events anyways
        if NeuroID.shared.configService.isSessionFlowSampled {
            // immediately flush events before anything else
            NeuroID.shared.send(forceSend: true) {
                completion()
            }
            return
        } else {
            // if not sampled clear any events that might have slipped through
            _ = NeuroID.shared.datastore.getAndRemoveAllEvents()

            completion()

            return
        }
    }
}
