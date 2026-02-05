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

extension NeuroID {
    func resumeCollection() {
        self.saveEventToLocalDataStore(
            NIDEvent.createInfoLogEvent("resume collection attempt")
        )
        // Don't allow resume to be called if SDK has not been started
        if self.identifierService.sessionID.isEmptyOrNil,
           !self.isSDKStarted
        {
            return
        }
        self._isSDKStarted = true
        self.sendCollectionEventsJob.start()
        self.collectGyroAccelEventJob.start()
    }

    func stopSession() -> Bool {
        self.saveEventToLocalDataStore(
            NIDEvent.createInfoLogEvent("Stop session attempt")
        )

        self.saveEventToLocalDataStore(
            NIDEvent(type: .closeSession, ct: "SDK_EVENT")
        )

        self.pauseCollection()

        self.clearSessionVariables()

        // Stop listening to changes in call status
        self.callObserver?.stopListeningToCallStatus()

        return true
    }

    /*
      Function to allow multiple use cases/flows within a single application
      Can be used as the original starting function and then use continuously
       throughout the rest of the session
      i.e. start/startSession/startAppFlow -> startAppFlow("site2") -> stop/stopSession
     */
    func startAppFlow(
        siteID: String,
        sessionID: String? = nil,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        _ = self.identifierService.logScrubbedIdentityAttempt(
            identifier: sessionID ?? "null",
            message: "StartAppFlow attempt with siteID: \(siteID), sessionID:"
        )

        if !self.verifyClientKeyExists() || !self.validationService.validateSiteID(siteID) {
            let res = SessionStartResult(false, "")

            self.linkedSiteID = nil

            self.saveEventToLocalDataStore(
                NIDEvent.createErrorLogEvent(
                    "Failed to set invalid Linked Site \(siteID)"
                )
            )

            completion(res)
            return
        }

        // Clear or Send events based on sample rate
        self.clearSendOldFlowEvents {
            // The following events have to happen for either
            //  an existing session that begins a new flow OR
            //  a new session with a new flow
            // 1. Determine if flow should be sampled
            // 2. CREATE_SESSION and MOBILE_METADATA events captured
            // 3. Capture ADV (based on global config and lib installed)

            // If SDK is already started, update sampleStatus and continue
            if self.isSDKStarted {
                self.configService.updateIsSampledStatus(siteID: siteID)

                // capture CREATE_SESSION and METADATA events for new flow
                self.saveEventToLocalDataStore(
                    self.createNIDSessionEvent()
                )
                self.captureMobileMetadata()

                self.captureAdvancedDevice(self.isAdvancedDevice)

                self.addLinkedSiteID(siteID)
                completion(
                    SessionStartResult(true, self.getSessionID())
                )

            } else {
                // If the SDK is not started we have to start it first
                //  (which will get the config using passed siteID)

                // if sessionID passed then startSession should be used
                if sessionID != nil {
                    self.startSession(siteID: siteID, sessionID: sessionID) { startStatus in
                        if !startStatus.started {
                            completion(startStatus)

                            self.saveEventToDataStore(
                                NIDEvent.createInfoLogEvent(
                                    "Failed to startAppFlow with inner startSession command"
                                )
                            )
                            return
                        }
                        self.addLinkedSiteID(siteID)
                        completion(startStatus)
                    }
                } else {
                    self.start(siteID: siteID) { started in
                        if !started {
                            completion(
                                SessionStartResult(started, self.getSessionID())
                            )

                            self.saveEventToDataStore(
                                NIDEvent.createInfoLogEvent(
                                    "Failed to startAppFlow with inner start command"
                                )
                            )
                            return
                        }

                        self.addLinkedSiteID(siteID)
                        completion(
                            SessionStartResult(started, self.getSessionID())
                        )
                    }
                }
            }
        }
    }

    func createNIDSessionEvent(
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
            metadata: DeviceMetadata(),
            sh: UIScreen.main.bounds.height,
            sw: UIScreen.main.bounds.width
        )
    }

    func createSession() {
        self.configService.updateIsSampledStatus(siteID: NeuroID.shared.linkedSiteID)
        saveEventToLocalDataStore(
            self.createNIDSessionEvent()
        )

        self.captureMobileMetadata()
    }

    func closeSession(skipStop: Bool = false) throws -> NIDEvent {
        saveEventToDataStore(
            NIDEvent.createInfoLogEvent("Close session attempt")
        )

        if !isSDKStarted {
            saveQueuedEventToLocalDataStore(
                NIDEvent.createErrorLogEvent("Close attempt failed since SDK is not started")
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

    func captureMobileMetadata() {
        let event = self.createNIDSessionEvent(sessionEvent: .mobileMetadataIOS)

        event.attrs = [
            Attrs(n: "orientation", v: ParamsCreator.getOrientation()),
            Attrs(n: "isRN", v: "\(NeuroID.shared.isRN)"),
        ]
        self.eventStorageService.saveEventToLocalDataStore(event)

        self.captureApplicationMetaData()
    }

    func clearSessionVariables() {
        identifierService.clearIDs()

        linkedSiteID = nil
    }

    func pauseCollection(flushEventQueue: Bool = false) {
        if flushEventQueue {
            // flush all events immediately before pause
            self.send(forceSend: true)
        }

        self._isSDKStarted = false

        self.sendCollectionEventsJob.cancel()
        self.collectGyroAccelEventJob.cancel()

        self.configService.clearSiteIDMap()
    }

    /**
     Function to setup all the required events and listeners for the beginning of a session
     - Will update sampling status
     - Wll create and trigger listeners
     - Will start swizzling
     - Will move queued events into main queue
     - Will make call to check/capture ADV event
     */
    func setupSession(
        siteID: String?,
        customFunctionality: @escaping () -> Void = {},
        completion: @escaping () -> Void = {}
    ) {
        // Use config cache or if first time, retrieve from server
        self.configService.retrieveOrRefreshCache()

        self.configService.updateIsSampledStatus(siteID: siteID)

        self._isSDKStarted = true

        self.setupListeners()

        self.createSession()
        self.swizzle()

        // custom functionality = the different timer starts (start vs. startSession)
        //  this will be refactored once we bring start/startSession in alignment
        customFunctionality()

        self.moveQueuedEventsToDataStore()

        self.captureAdvancedDevice(self.isAdvancedDevice)

        completion()
    }

    // Internal implementation that allows a siteID
    func start(
        siteID: String?,
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        self.saveEventToDataStore(
            NIDEvent.createInfoLogEvent("Start attempt with siteID: \(siteID ?? ""))")
        )

        if !self.verifyClientKeyExists() {
            completion(false)
            return
        }

        // Setup Session with old start timer logic
        // TO-DO - Refactor to behave like startSession
        self.setupSession(
            siteID: siteID,
            customFunctionality: {
                #if DEBUG
                    if NSClassFromString("XCTest") == nil {
                        self.sendCollectionEventsJob.start()
                    }
                #else
                    self.sendCollectionEventsJob.start()
                #endif
                self.collectGyroAccelEventJob.start()
            }
        ) {
            completion(true)
        }
    }

    // Internal implementation that allows a siteID
    func startSession(
        siteID: String?,
        sessionID: String? = nil,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        if !self.verifyClientKeyExists() {
            completion(
                SessionStartResult(false, "")
            )
            return
        }

        // stop existing session if one is open
        if !self.identifierService.sessionID.isEmptyOrNil || self.isSDKStarted {
            _ = self.stopSession()
        }

        // If sessionID is nil, set origin as NID here
        let userGenerated = sessionID != nil

        let finalSessionID = sessionID ?? ParamsCreator.generateID()

        _ = self.identifierService.logScrubbedIdentityAttempt(
            identifier: finalSessionID,
            message: "StartSession attempt with siteID: \(siteID ?? ""), sessionID:"
        )

        let validSessionID = self.identifierService.setSessionID(
            finalSessionID,
            userGenerated
        )

        if !validSessionID {
            completion(
                SessionStartResult(false, "")
            )
            return
        }

        self.setupSession(
            siteID: siteID,
            customFunctionality: {
                #if DEBUG
                    if NSClassFromString("XCTest") == nil {
                        self.resumeCollection()
                    }
                #else
                    self.resumeCollection()
                #endif
            }
        ) {
            completion(SessionStartResult(true, finalSessionID))
        }
    }

    func clearSendOldFlowEvents(completion: @escaping () -> Void = {}) {
        // if the session is being sampled we should send, else we don't want those events anyways
        if self.configService.isSessionFlowSampled {
            // immediately flush events before anything else
            self.send(forceSend: true) {
                completion()
            }
            return
        } else {
            // if not sampled clear any events that might have slipped through
            _ = self.datastore.getAndRemoveAllEvents()

            completion()

            return
        }
    }
}
