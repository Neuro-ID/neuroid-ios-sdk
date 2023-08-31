//
//  BaseClassExtensionTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 8/30/23.
//

@testable import NeuroID
import XCTest

class BaseClassExtenstionTests: XCTestCase {
    func test_string_sha256_withSalt() {
        UserDefaults.standard.set("mySalt", forKey: Constants.storageSaltKey.rawValue)
        let og = "myString"
        
        let value = og.sha256()
        
        assert(value == "bbed32651d5c168d7bd222adc04b8b53655ec5db8ca0d4a5ad30a250fcc6c5bc")
    }
    
    func test_string_sha256_withOutSalt() {
        UserDefaults.standard.set("", forKey: Constants.storageSaltKey.rawValue)
        let og = "myString"
        
        let value = og.sha256()
        
        let generatedSalt = UserDefaults.standard.string(forKey: Constants.storageSaltKey.rawValue) ?? ""
        
        assert(generatedSalt != "")
        
        let secondValue = og.sha256()
        
        assert(value == secondValue)
    }
    
    func test_double_truncate() {
        let og = 1.0101
        
        let value = og.truncate(places: 1)
        assert(value == 1.0)
        
        let value2 = og.truncate(places: 2)
        assert(value2 == 1.01)
    }
    
    func test_dictionary_toKeyValueString() {
        var og = ["foo": "bar"]
        
        let value = og.toKeyValueString()
        assert(value == "foo=bar")
        
        og["foo2"] = "bar2"
        
        let value2 = og.toKeyValueString()
        assert(value2 == "foo=bar&foo2=bar2")
    }
    
    func test_optional_isEmptyOrNil() {
        let og: String? = "test"
        
        if og.isEmptyOrNil {
            assertionFailure("String is not empty or nil")
        }
    }
    
    func test_optional_isEmptyOrNil_nil() {
        let og: String? = nil
        
        if !og.isEmptyOrNil {
            assertionFailure("String is nil")
        }
    }
    
    func test_optional_isEmptyOrNil_empty() {
        let og: String? = ""
        
        if !og.isEmptyOrNil {
            assertionFailure("String is empty")
        }
    }
    
    func test_date_toString() {
        let og = Date()
        
        let value = og.toString()
        
        assert(value.count == 19)
    }
}
