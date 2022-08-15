//
//  PayloadTest.swift
//  SDKTest
//
//  Created by jose perez on 12/08/22.
//

import XCTest
import NeuroID
import JSONSchema

class PayloadTest: XCTestCase {
    
    var schema: [String:Any]!
    
    override func setUpWithError() throws {
        do {
            /// This path may point to your on file system
            let url = URL(fileURLWithPath: "/Users/joseperez/Developer/Projects/swift/neuroid-ios-sdk/NeuroID/schema.json")
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            if let json = jsonResult as? [String:Any] {
                self.schema = json
            }
            
        } catch {
            print("Not Found")
        }
    }
    func testPaylaodSchema() {
        do {
            let entity = NIDEvent(type: .radioChange, tg: ["name":TargetValue.string("clay")], view: UIView())
            let neuroHTTPRequest = NeuroHTTPRequest.init(clientId: "1", environment: NeuroID.getEnvironment(), sdkVersion: "2.0.0", pageTag: NeuroID.getScreenName() ?? "UNKNOWN", responseId: "2", siteId: "", userId: "", jsonEvents: [entity])
            let jsonEncoder = JSONEncoder()
            let data = try jsonEncoder.encode(neuroHTTPRequest)
            let object = try JSONSerialization.jsonObject(with: data)
            print(object)
            let validate = try JSONSchema.validate(object, schema: self.schema)
            switch validate {
            case .valid:
                XCTAssert(true)
            case .invalid(let array):
                array.forEach({ print ("\($0) \n")})
                XCTAssert(true)
            }
        } catch {
            print(error)
            XCTAssert(false)
        }
    }
    
}
