//
//  EventTests.swift
//  Neuro-ID-SDKTests
//
//  Created by Ky Nguyen on 4/30/21.
//

import XCTest
@testable import Neuro_ID_SDK

class EventTests: XCTestCase {
    let clientKey = "this_is_the_client_key_from_NeuroID"
    let userId = "kynguyen"
    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey, userId: userId)
    }

    func testEventParams() throws {
        let urlName = "HomeScreen"
        let tracker = NeuroIDTracker(userUrl: urlName)

        let copyEvent = NIEvent(type: .copy, tg: ["et": "fieldset"], x: 10, y: 10)
        let params = tracker.getEventParams(event: copyEvent, userUrl: urlName)

        XCTAssertTrue(params["key"] != nil)
        XCTAssertTrue(params["key"] as! String == clientKey)

        XCTAssertTrue(params["sessionId"] != nil)
        XCTAssertTrue((params["sessionId"] as! String).count == 16,
                      "SessionId has 16 random digits")

        XCTAssertTrue(params["userId"] != nil)
        XCTAssertTrue(params["userId"] as! String == userId)

        XCTAssertTrue(params["pageId"] != nil)
        XCTAssertTrue(params["events"] != nil)
        XCTAssertTrue(params["events"] is [String: Any])
        let events = params["events"] as! [String: Any]
        XCTAssertTrue(events["type"] as! String == "COPY")
        XCTAssertTrue(events["x"] as! Int == 10)
        XCTAssertTrue(events["y"] as! Int == 10)
    }
}
