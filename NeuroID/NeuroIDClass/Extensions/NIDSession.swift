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
            jsv: ParamsCreator.getSDKVersion(),
            sh: UIScreen.main.bounds.height,
            sw: UIScreen.main.bounds.width,
            metadata: NIDMetadata()
        )
    }

    static func clearSession() {
        setUserDefaultKey(Constants.storageSiteIdKey.rawValue, value: nil)
    }

    // Sessions are created under conditions:
    // Launch of application
    // If user idles for > 30 min
    static func getSessionID() -> String {
        // We don't do anything with this?
        let _ = Constants.storageSessionExpiredKey.rawValue

        let sidKeyName = Constants.storageSiteIdKey.rawValue

        let sid = getUserDefaultKeyString(sidKeyName)

        // TODO: Expire sesions
        if let sidValue = sid {
            return sidValue
        }

        let id = ParamsCreator.genId()
        setUserDefaultKey(sidKeyName, value: id)

        NIDPrintLog("\(Constants.sessionTag.rawValue)", id)
        return id
    }

    static func createSession() {
        // Since we are creating a new session, clear any existing session ID
        NeuroID.clearSession()
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

        NeuroID.stop()
        return closeEvent
    }

    static func captureMobileMetadata() {
        let event = createNIDSessionEvent(sessionEvent: .mobileMetadataIOS)

        event.attrs = [
            Attrs(n: "orientation", v: ParamsCreator.getOrientation()),
        ]
        saveEventToLocalDataStore(event)
    }
}
