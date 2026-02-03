//
//  BaseClassExtensionTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 8/30/23.
//

import Foundation
import Testing

@testable import NeuroID

@Suite("Base Class Extensions Tests")
struct BaseClassExtensionTests {
    @Test func string_sha256_withSalt() {
        UserDefaults.standard.set("mySalt", forKey: Constants.storageSaltKey.rawValue)
        let og = "myString"
        
        let value = og.sha256()
        
        assert(value == "bbed32651d5c168d7bd222adc04b8b53655ec5db8ca0d4a5ad30a250fcc6c5bc")
    }
    
    @Test func string_sha256_withOutSalt() {
        UserDefaults.standard.set("", forKey: Constants.storageSaltKey.rawValue)
        let og = "myString"
        
        let value = og.sha256()
        
        let generatedSalt = UserDefaults.standard.string(forKey: Constants.storageSaltKey.rawValue) ?? ""
        
        assert(generatedSalt != "")
        
        let secondValue = og.sha256()
        
        assert(value == secondValue)
    }
    
    @Test func optional_isEmptyOrNil() {
        let og: String? = "test"
        
        if og.isEmptyOrNil {
            assertionFailure("String is not empty or nil")
        }
    }
    
    @Test func optional_isEmptyOrNil_nil() {
        let og: String? = nil
        
        if !og.isEmptyOrNil {
            assertionFailure("String is nil")
        }
    }
    
    @Test func optional_isEmptyOrNil_empty() {
        let og: String? = ""
        
        if !og.isEmptyOrNil {
            assertionFailure("String is empty")
        }
    }
    
    @Test func date_toString() {
        let og = Date()
        
        let value = og.toString()
        
        assert(value.count == 19)
    }
}
