//
//  PayloadTest.swift
//  SDKTest
//
//  Created by jose perez on 12/08/22.
//

import DSJSONSchemaValidation
import JSONSchema
@testable import NeuroID
import XCTest

class PayloadTest: XCTestCase {
    var schema: [String: Any]!
    var data: Data!

    override func setUpWithError() throws {
        do {
            /// This path may point to your on file system
            var url = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            url.appendPathComponent("/Source/NeuroID/schema.json")
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            self.data = data
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            if let json = jsonResult as? [String: Any] {
                self.schema = json
            }

        } catch {
            print("**** Schema Not Found ****")

            self.data = Data()
        }
    }

    func testPayloadSchema() {
        do {
            let entity = NIDEvent(type: .radioChange, tg: ["url": TargetValue.string("clay")])
            let neuroHTTPRequest = NeuroHTTPRequest(
                clientID: "1",
                environment: NeuroID.getEnvironment(),
                sdkVersion: "2.0.0",
                pageTag: NeuroID.getScreenName() ?? "UNKNOWN",
                responseID: "2",
                siteID: "",
                linkedSiteID: nil,
                sessionID: "",
                registeredUserID: "",
                jsonEvents: [entity],
                tabID: "",
                pageID: "",
                url: "",
                packetNumber: 3
            )
            let jsonEncoder = JSONEncoder()
            let data = try jsonEncoder.encode(neuroHTTPRequest)
            let object = try JSONSerialization.jsonObject(with: data)
            if let JSONString = String(data: data, encoding: String.Encoding.utf8) {
                print(JSONString)
            }
            let validate = JSONSchema.validate(object, schema: self.schema)
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
            let entity = NIDEvent(type: .radioChange, tg: ["url": TargetValue.string("clay")])
            let neuroHTTPRequest = NeuroHTTPRequest(
                clientID: "A0CDADAD-1BD3-4570-AA8E-AFF517EFC775",
                environment: NeuroID.getEnvironment(),
                sdkVersion: "2.0.0",
                pageTag: NeuroID.getScreenName() ?? "UNKNOWN",
                responseID: "D726B802",
                siteID: "",
                linkedSiteID: nil,
                sessionID: "",
                registeredUserID: "",
                jsonEvents: [entity],
                tabID: "",
                pageID: "",
                url: "",
                packetNumber: 1
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
