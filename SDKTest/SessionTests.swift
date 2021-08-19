//
//  SDKTest.swift
//  SDKTest
//
//  Created by Clayton Selby on 8/19/21.
//

import XCTest

class SessionTests: XCTestCase {
    let clientKey = "this_is_the_client_key_from_NeuroID"
    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey, userId: "kynguyen")
    }

    func testSessionParams() throws {
        let urlName = "HomeScreen"
        let tracker = NeuroIDTracker(userUrl: urlName)
        let params = tracker.getSessionParams(userUrl: urlName)

        XCTAssertTrue(params["key"] != nil)
        XCTAssertTrue(params["key"] as! String == clientKey)

        XCTAssertTrue(params["sessionId"] != nil)
        XCTAssertTrue((params["sessionId"] as! String).count == 16,
                      "SessionId has 16 random digits")

        XCTAssertTrue(params["clientId"] != nil)
        let clientId = params["clientId"] as! String
        XCTAssertTrue(clientId.lastIndex(of: ".") == clientId.firstIndex(of: "."),
                      "Only one . in the clientId")

        let clientIdComponents = clientId.components(separatedBy: ".")
        let time = Double(clientIdComponents[0])!
        XCTAssertTrue(time < Date().timeIntervalSince1970 * 1000,
                      "Created time should be in the past")

        let randomNumber = Double(clientIdComponents[1])!
        XCTAssertTrue(randomNumber <= Double(Int32.max),
                      "number was randomed in 0 ..< Int32.max")

        XCTAssertTrue(params["url"] != nil)
        XCTAssertTrue(params["url"] as! String == urlName)

        XCTAssertTrue(params["language"] != nil)
        XCTAssertTrue((params["language"] as! String).count == 2,
                      "ISO 639-1 language code, 2 letters")

        XCTAssertTrue(params["screenWidth"] != nil)
        XCTAssertTrue(params["screenWidth"] as! CGFloat == UIScreen.main.bounds.width)

        XCTAssertTrue(params["screenHeight"] != nil)
        XCTAssertTrue(params["screenHeight"] as! CGFloat == UIScreen.main.bounds.height)
    }

}
