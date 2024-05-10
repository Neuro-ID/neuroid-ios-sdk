//
//  PayloadTest.swift
//  SDKTest
//
//  Created by jose perez on 12/08/22.
//

import DSJSONSchemaValidation
import JSONSchema
import NeuroID
import XCTest

class PayloadTest: XCTestCase {
    var schema: [String: Any]!
    var data: Data!

    override func setUpWithError() throws {
        do {
            /// This path may point to your on file system
            var url = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent()
            url.appendPathComponent("/NeuroID/schema.json")
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            self.data = data
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            if let json = jsonResult as? [String: Any] {
                self.schema = json
            }

        } catch {
            print("Not Found")
            self.data = Data()
        }
    }

    func testPayloadSchema() {
        do {
            let entity = NIDEvent(type: .radioChange, tg: ["url": TargetValue.string("clay")], view: UIView())
            let neuroHTTPRequest = NeuroHTTPRequest(
                clientID: "1",
                environment: NeuroID.getEnvironment(),
                sdkVersion: "2.0.0",
                pageTag: NeuroID.getScreenName() ?? "UNKNOWN",
                responseID: "2",
                siteID: "",
                linkedSiteId: nil,
                userID: "",
                registeredUserID: "",
                jsonEvents: [entity],
                tabID: "",
                pageID: "",
                url: ""
            )
            let jsonEncoder = JSONEncoder()
            let data = try jsonEncoder.encode(neuroHTTPRequest)
            let object = try JSONSerialization.jsonObject(with: data)
            if let JSONString = String(data: data, encoding: String.Encoding.utf8) {
                print(JSONString)
            }
            let validate = try JSONSchema.validate(object, schema: self.schema)
            switch validate {
            case .valid:
                XCTAssert(true)
            case .invalid(let array):
                array.forEach { print("\($0) \n") }
                XCTAssert(true)
            }
        } catch {
            print(error)
            XCTAssert(false)
        }
    }

    func testNewPayloadSchema() {
        do {
            let schema = try DSJSONSchema(data: data, baseURI: nil, referenceStorage: nil, specification: DSJSONSchemaSpecification.draft6(), options: nil)
            let entity = NIDEvent(type: .radioChange, tg: ["url": TargetValue.string("clay")], view: UIView())
            let neuroHTTPRequest = NeuroHTTPRequest(
                clientID: "A0CDADAD-1BD3-4570-AA8E-AFF517EFC775",
                environment: NeuroID.getEnvironment(),
                sdkVersion: "2.0.0",
                pageTag: NeuroID.getScreenName() ?? "UNKNOWN",
                responseID: "D726B802",
                siteID: "",
                linkedSiteId: nil,
                userID: "",
                registeredUserID: "",
                jsonEvents: [entity],
                tabID: "",
                pageID: "",
                url: ""
            )
            let jsonEncoder = JSONEncoder()
            let data = try jsonEncoder.encode(neuroHTTPRequest)
            try schema.validateObject(with: data)
            XCTAssert(true)
        } catch let validationError as NSError {
            print(validationError)
            XCTAssert(true)
        } catch {
            print(error)
            XCTAssert(false)
        }
    }
}
