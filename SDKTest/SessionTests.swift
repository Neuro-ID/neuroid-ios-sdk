//
//  SDKTest.swift
//  SDKTest
//
//  Created by Clayton Selby on 8/19/21.
//

@testable import NeuroID
import XCTest

class SessionTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"

    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey)
        NeuroID.clearStoredSessionID()
        let _ = NeuroID.start()
        DataStore.removeSentEvents()
        UserDefaults.standard.removeObject(forKey: Constants.storageSessionIDKey.rawValue)
    }

    func testConfigureEndpoint() throws {
        #if DEBUG
        XCTAssertTrue(NeuroID.getCollectionEndpointURL() == "https://receiver.neuroid.cloud/c")
        #elseif STAGING
        XCTAssertTrue(NeuroID.getCollectionEndpointURL() == "https://receiver.neuroid.cloud/c")
        #else
        XCTAssertTrue(NeuroID.getCollectionEndpointURL() == "https://receiver.neuroid.cloud/c")
        #endif
    }

    func testCreateSession() throws {
        // As soon as we load a view we should create a swession
        let urlName = "HomeScreen"
        let testView = UIViewController()
        let tracker = NeuroIDTracker(screen: urlName, controller: testView)
        let session = NeuroID.getSessionID()
        NeuroID.groupAndPOST()
//        XCTAssertTrue(session == nil)
    }

    func testRandom() throws {
        let dictRandom = ["events": "eventstringt", "status": "pending"]
        if let key = dictRandom.first(where: { $0.value == "pending" })?.key {
            NIDLog.log(key)
        }
    }

    func testTextInputEvents() throws {
        let urlName = "FormScreenText"
        let testView = LoanViewControllerPersonalDetails()
        testView.view.id = "LoanViewControllerPersonalDetails"
        let sampleTextField = UITextField(frame: CGRect(x: 20, y: 100, width: 300, height: 40))
        sampleTextField.accessibilityLabel = "FName"
        sampleTextField.placeholder = "First Name"
        sampleTextField.id = "horray"
        testView.view.addSubview(sampleTextField)
        testView.viewDidLoad()
        testView.beginAppearanceTransition(true, animated: false)

//        testView.endAppearanceTransition()
        let _ = NeuroIDTracker(screen: urlName, controller: testView)
        let charsToInput = ["C", "l", "a", "y"]
        for c in charsToInput {
            sampleTextField.insertText(c)
        }
    }

//    func testDetectingTextFieldsForRegsitering() throws {
//        let urlName = "TextFieldScreen"
//        let testView = LoanViewControllerPersonalDetails();
//        let sampleTextField =  UITextField(frame: CGRect(x: 20, y: 100, width: 300, height: 40))
//        sampleTextField.accessibilityLabel = "Lname"
//        sampleTextField.placeholder = "Last Name"
//        testView.view.addSubview(sampleTextField);
//
    // Call this to force the viewWillLoad hook
//        testView.beginAppearanceTransition(true, animated: false)
//        testView.endAppearanceTransition()
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let sut = storyboard.instantiateViewController(identifier: "testView")
    ////        sut.presenter = presenter
//        sut.loadViewIfNeeded()
//

//    }
}

class LoanViewControllerPersonalDetails: UIViewController {
//    override func viewDidLoad() {

//        let moreInfoController = UIViewController();
//        let moreInfoSubView = UITextView();
//        moreInfoController.view.addSubview(moreInfoSubView);
//
//        let aboutMe = UITextView()
//
//        aboutMe.id = "aboutMe"
//        let myName = UITextField()
//        myName.id = "myName"
//
//        self.view.addSubview(aboutMe)
//        self.view.addSubview(myName)
//        self.addChild(moreInfoController)
    // MUST call super at the end of the method to ensure we capture all the added views
//        super.viewDidLoad();
//
//    }
}

//
// class LoanViewControllerWorkDetails: UIViewController {
//
// }
