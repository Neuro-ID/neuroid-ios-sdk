//
//  SDKTest.swift
//  SDKTest
//
//  Created by Clayton Selby on 8/19/21.
//

import XCTest
@testable import NeuroID

class SessionTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"
    
    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey)
    }

    func testCreateSession() throws {
        let urlName = "HomeScreen"
        let testView = UIViewController();
        let tracker = NeuroIDTracker(screen: urlName, controller: testView);
        let session = tracker.getCurrentSession();
        XCTAssertTrue(session.url == urlName)
    }
    
    func testTextInputEvents() throws {
        let urlName = "FormScreenText"
        let testView = UIViewController();
        let sampleTextField =  UITextField(frame: CGRect(x: 20, y: 100, width: 300, height: 40))
        sampleTextField.accessibilityLabel = "FName"
        sampleTextField.placeholder = "First Name"
        sampleTextField.id = "horray"
        testView.view.addSubview(sampleTextField);
        NeuroIDTracker(screen: urlName, controller: testView);
        let charsToInput = ["C", "l", "a", "y"]
        // Simulate a user typing
        for c in charsToInput {
            sampleTextField.insertText(c)
        }
    }
    
    func testDetectingTextFieldsForRegsitering() throws {
        let urlName = "TextFieldScreen"
        let testView = UIViewController();
        let sampleTextField =  UITextField(frame: CGRect(x: 20, y: 100, width: 300, height: 40))
        sampleTextField.accessibilityLabel = "Lname"
        sampleTextField.placeholder = "Last Name"
        testView.view.addSubview(sampleTextField);
        
        // Call this to force the viewWillLoad hook
        testView.beginAppearanceTransition(true, animated: false)
        testView.endAppearanceTransition()
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let sut = storyboard.instantiateViewController(identifier: "testView")
////        sut.presenter = presenter
//        sut.loadViewIfNeeded()
//
        
        
    }
    
    func testSessionParams() throws {
        let urlName = "HomeScreen"
        let testView = UIViewController();

        let tracker = NeuroIDTracker(screen: urlName, controller: testView);
        
        let params = ParamsCreator.getDefaultSessionParams();
//            tracker.getSessionParams(userUrl: urlName)

        XCTAssertTrue(params["key"] != nil)
        XCTAssertTrue(params["key"] as! String == clientKey)

        XCTAssertTrue(params["sid"] != nil)
        XCTAssertTrue((params["sid"] as! String).count == 16,
                      "SessionId has 16 random digits")

        XCTAssertTrue(params["cid"] != nil)
        let clientId = params["cid"] as! String
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
//        XCTAssertTrue(params["url"] as! String == urlName)
//
//        XCTAssertTrue(params["language"] != nil)
//        XCTAssertTrue((params["language"] as! String).count == 2,
//                      "ISO 639-1 language code, 2 letters")
//
//        XCTAssertTrue(params["screenWidth"] != nil)
//        XCTAssertTrue(params["screenWidth"] as! CGFloat == UIScreen.main.bounds.width)
//
//        XCTAssertTrue(params["screenHeight"] != nil)
//        XCTAssertTrue(params["screenHeight"] as! CGFloat == UIScreen.main.bounds.height)
    }

}
