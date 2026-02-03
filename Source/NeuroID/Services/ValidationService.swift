//
//  ValidationService.swift
//  NeuroID
//
//  Created by Kevin Sites on 1/27/25.
//

import Foundation

protocol ValidationServiceProtocol {
    func validateClientKey(_ clientKey: String) -> Bool
    func validateSiteID(_ string: String) -> Bool
    func validateIdentifier(_ identifier: String) -> Bool
}

class ValidationService: ValidationServiceProtocol {

    func validateClientKey(_ clientKey: String) -> Bool {
        var validKey = false

        let pattern = "key_(live|test)_[A-Za-z0-9]+"
        let regex = try! NSRegularExpression(pattern: pattern)

        if regex.firstMatch(
            in: clientKey,
            options: NSRegularExpression.MatchingOptions(rawValue: 0),
            range: NSMakeRange(0, clientKey.count)) != nil
        {
            validKey = true
        } else {
            NIDLog.e("Invalid ClientKey")
        }

        return validKey
    }

    func validateSiteID(_ string: String) -> Bool {
        let regex = #"^form_[a-zA-Z0-9]{5}\d{3}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)

        let valid = predicate.evaluate(with: string)

        if !valid {
            NIDLog.e("Invalid SiteID/AppID")
        }

        return valid
    }

    func validateIdentifier(_ identifier: String) -> Bool {
        // user ids must be from 3 to 100 ascii alhpa numeric characters and can include `.`, `-`, and `_`
        do {
            let expression = try NSRegularExpression(
                pattern: "^[a-zA-Z0-9-_.]{3,100}$",
                options: NSRegularExpression.Options(rawValue: 0))
            let result = expression.matches(
                in: identifier,
                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                range: NSMakeRange(0, identifier.count))
            if result.count != 1 {
                NIDLog.e(NIDError.invalidUserID.rawValue)
                return false
            }
        } catch {
            NIDLog.e(NIDError.invalidUserID.rawValue)
            return false
        }
        return true
    }
}
