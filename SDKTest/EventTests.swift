//
//  EventTests.swift
//  SDKTest
//
//  Created by Clayton Selby on 8/19/21.
//

import XCTest
@testable import NeuroID

class EventTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"
    let userId = "form_mobilesandbox"
    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey, userId: userId)
    }

    func testLocale() {
        print("Locale: ", ParamsCreator.getLocale())
        XCTAssertTrue(ParamsCreator.getLocale() != nil);
    }
    
    func testUserAgent() {
        let data = ParamsCreator.getUserAgent();
        print("User Agent: ", data)
        XCTAssertTrue(data != nil);
    }
    
    func testTimeZoneOffset() {
        let data = ParamsCreator.getTimezone();
        print("TimeZone Offset: ", data)
        XCTAssertTrue(data != nil);
    }
    
    func testLanguage() {
        let data = ParamsCreator.getLanguage();
        print("Language: ", data)
        XCTAssertTrue(data != nil);
    }
    
    func testPlatform() {
        let data = ParamsCreator.getPlatform();
        print("Platform: ", data)
        XCTAssertTrue(data != nil);
    }
    
    func testDnt(){
        let data = ParamsCreator.getDnt();
        print("Dnt: ", data)
        XCTAssertTrue(data != nil);
    }
    
    func testTouch(){
        let data = ParamsCreator.getTouch();
        print("Touch: ", data)
        XCTAssertTrue(data != nil);
    }
    
    func testSDKVersion(){
        let data = ParamsCreator.getSDKVersion()
        print("Version: ", data)
        XCTAssertTrue(data != nil);
    }
    
    func testCommandQueueNameSpace(){
        let data = ParamsCreator.getCommandQueueNamespace()
        print("Namespace: ", data)
        XCTAssertTrue(data != nil);
    }
    
    func testEventParams() throws {
//        let urlName = "HomeScreen"
//        let tracker = NeuroIDTracker(userUrl: urlName)
        
        let urlName = "HomeScreen"
        let testView = UIViewController();

        let tracker = NeuroIDTracker(screen: urlName, controller: testView);
//        let params = ParamsCreator.getDefaultSessionParams();

        let copyEvent = NIEvent(type: .copy, tg: ["et": "fieldset"], x: 10, y: 10)
        let params = ParamsCreator.getDefaultEventParams()
//        let params = tracker.getEventParams(event: copyEvent, userUrl: urlName)

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
