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
        NeuroID.configure(clientKey: clientKey)
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
    func testSessionExpired() {
        let data = ParamsCreator.isSessionExpired();
        XCTAssertTrue(true);
    }
    
    func testCreateSessionID() {
        
        NeuroID.logError(content: "NeuroID client key not setup")
        let data = ParamsCreator.getSessionID();
        let sidName =  "nid_sid"
        let defaults = UserDefaults.standard
        var sid = defaults.string(forKey: sidName)
        print("User Session ID: ", sid!)
        XCTAssertTrue(sid != nil);
    }
    
    func testSettingAndGettingAPIClientKey(){
        let keyLookup = NeuroID.getClientKeyFromLocalStorage();
        print("Key lookup:", keyLookup)
        XCTAssertTrue(keyLookup == clientKey)
    }
    
    func testGetTimeStamp(){
        let data = ParamsCreator.getTimeStamp();
        print("Timestamp: ", data)
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
    
    func testGetBaseURL(){
        let data = NeuroID.getBaseURL();
        print("URL: ", data)
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
    
    func testStoppingSDKIsStoppedFalse(){
        if (NeuroID.isStopped()) {
            NeuroID.start();
        }
        let isStopped = NeuroID.isStopped()
        print("Is Stopped", isStopped)
        XCTAssertTrue(!isStopped);
    }
    
    func testStoppingSDKIsStoppedTrue(){
        NeuroID.stop()
        let isStopped = NeuroID.isStopped()
        print("Is Stopped", isStopped)
        XCTAssertTrue(isStopped);
    }
    
    func testSetIUserID(){
        NeuroID.setUserID("atestUserID")
        let params = ParamsCreator.getDefaultSessionParams()
        let uid = params["uid"] as! String
        XCTAssert(uid == "atestUserID")
    }
    func testEventParams() throws {
//        let urlName = "HomeScreen"
//        let tracker = NeuroIDTracker(userUrl: urlName)
        
        let urlName = "HomeScreen"
        let testView = UIViewController();

        let tracker = NeuroIDTracker(screen: urlName, controller: testView);
//        let params = ParamsCreator.getDefaultSessionParams();

//        let copyEvent = NIDEvent(type: .copy, tg: ["et": "fieldset"], x: 10, y: 10)
        let params = ParamsCreator.getDefaultSessionParams()
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
    
    func testEventSubmitForm(){
        let event = NeuroID.formSubmit()
        XCTAssertTrue(event.type == NIDEventName.applicationSubmit.rawValue)
    }
    
    func testEventSubmitFormFailure(){
        let event = NeuroID.formSubmitFailure()
        XCTAssertTrue(event.type == NIDEventName.applicationSubmitFailure.rawValue)
    }
    
    func testEventSubmitFormSuccess(){
        let event = NeuroID.formSubmitSuccess()
        XCTAssertTrue(event.type == NIDEventName.applicationSubmitSuccess.rawValue)
    }
    
    func testEventSetVariable(){
        let event = NeuroID.setCustomVariable(key: "test", v: "test2")
        XCTAssertTrue(event.type == NIDSessionEventName.setVariable.rawValue)
    }
}
