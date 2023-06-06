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
        UserDefaults.standard.set(nil, forKey: Constants.storageClientKeyAlt.rawValue)
    }

    static func getSessionID() -> String? {
        return UserDefaults.standard.string(forKey: Constants.storageSiteIdKey.rawValue)
    }

    static func createSession() {
        // Since we are creating a new session, clear any existing session ID
        NeuroID.clearSession()
        // TODO, return session if already exists
        var event = NIDEvent(
            session: .createSession,
            f: ParamsCreator.getClientKey(),
            sid: ParamsCreator.getSessionID(),
            lsid: nil,
            cid: ParamsCreator.getClientId(),
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
            jsv: ParamsCreator.getSDKVersion()
        )
        event.sh = UIScreen.main.bounds.height
        event.sw = UIScreen.main.bounds.width
        event.metadata = NIDMetadata()
        saveEventToLocalDataStore(event)
    }

    static func closeSession(skipStop: Bool = false) throws -> NIDEvent {
        if !NeuroID.isSDKStarted {
            throw NIDError.sdkNotStarted
        }
        var closeEvent = NIDEvent(type: NIDEventName.closeSession)
        closeEvent.ct = "SDK_EVENT"
        saveEventToLocalDataStore(closeEvent)
        if skipStop {
            return closeEvent
        }

        NeuroID.stop()
        return closeEvent
    }
}
