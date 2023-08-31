//
//  NIDSession.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation
import UIKit

public extension NeuroID {
    static func clearSession() {
        UserDefaults.standard.set(nil, forKey: Constants.storageSiteIdKey.rawValue)
    }

    // Sessions are created under conditions:
    // Launch of application
    // If user idles for > 30 min
    static func getSessionID() -> String {
        // We don't do anything with this?
        let sidExpires = Constants.storageSessionExpiredKey.rawValue

        let sidKeyName = Constants.storageSiteIdKey.rawValue

        let sid = UserDefaults.standard.string(forKey: sidKeyName)

        // TODO: Expire sesions
        if let sidValue = sid {
            return sidValue
        }

        let id = UUID().uuidString
        UserDefaults.standard.setValue(id, forKey: sidKeyName)

        NIDPrintLog("\(Constants.sessionTag.rawValue)", id)
        return id
    }

    static func createSession() {
        // Since we are creating a new session, clear any existing session ID
        NeuroID.clearSession()
        // TODO, return session if already exists
        let event = NIDEvent(
            session: .createSession,
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
        let event = NIDEvent(
            session: .mobileMetadataIOS,
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

        event.attrs = [
            Attrs(n: "orientation", v: ParamsCreator.getOrientation()),
        ]
        saveEventToLocalDataStore(event)
    }
}
