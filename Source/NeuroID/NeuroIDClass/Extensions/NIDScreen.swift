//
//  NIDScreen.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation

extension NeuroID {
    /**
     Set screen name. We ensure that this is a URL valid name by replacing non alphanumber chars with underscore
     */
    func setScreenName(_ screen: String) -> Bool {
        if !self.isSDKStarted {
            NIDLog.e(NIDError.sdkNotStarted.rawValue)
            return false
        }

        if let urlEncode = screen.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            self._currentScreenName = urlEncode
        } else {
            NIDLog.e("Invalid Screenname for NeuroID. \(screen) can't be encode")
            return false
        }

        self.captureMobileMetadata()

        return true
    }

    func getScreenName() -> String? {
        if !self._currentScreenName.isEmptyOrNil {
            return "\(self._currentScreenName ?? "")"
        }
        return self._currentScreenName
    }
}
