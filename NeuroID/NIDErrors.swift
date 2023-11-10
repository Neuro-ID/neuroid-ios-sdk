//
//  NIDErrors.swift
//  NeuroID
//
//  Created by Clayton Selby on 11/30/22.
//

import Foundation

public enum NIDError: String, LocalizedError {
    case sdkNotStarted = "The NeuroID SDK is not started"
    case urlError = "The URL is not valid"
    case invalidUserID = "The UserID is invalid"
    case missingClientKey = "The Client Key is missing"

    public var errorDescription: String? { self.rawValue }
}
