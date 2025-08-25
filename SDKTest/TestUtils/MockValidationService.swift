//
//  MockValidationService.swift
//  NeuroID
//
//  Created by Kevin Sites on 8/25/25.
//

@testable import NeuroID

class MockValidationService: ValidationServiceProtocol {
    var validClientKey = true
    var validSiteID = true
    var validIdentifier = true

    func validateClientKey(_ clientKey: String) -> Bool { self.validClientKey }
    func validateSiteID(_ string: String) -> Bool { self.validSiteID }
    func validateIdentifier(_ identifier: String) -> Bool { self.validIdentifier }
}
