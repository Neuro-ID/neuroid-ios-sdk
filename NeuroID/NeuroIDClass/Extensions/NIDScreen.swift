//
//  NIDScreen.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation

public extension NeuroID {
    /**
     Set screen name. We ensure that this is a URL valid name by replacing non alphanumber chars with underscore
     */
    static func setScreenName(_ screen: String) -> Bool {
        if !NeuroID.isSDKStarted {
            NIDLog.e(NIDError.sdkNotStarted.rawValue)
            return false
        }

        if let urlEncode = screen.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            currentScreenName = urlEncode
        } else {
            NIDLog.e("Invalid Screenname for NeuroID. \(screen) can't be encode")
            logError(content: "Invalid Screenname for NeuroID. \(screen) can't be encode")
            return false
        }

        captureMobileMetadata()

        return true
    }

    static func getScreenName() -> String? {
        if !currentScreenName.isEmptyOrNil {
            return "\(currentScreenName ?? "")"
        }
        return currentScreenName
    }
}
