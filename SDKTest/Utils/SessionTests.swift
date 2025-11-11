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
        let configuration = Configuration(clientKey: clientKey, isAdvancedDevice: false)
        _ = NeuroID.configure(configuration)

        NeuroID.shared._isSDKStarted = true
        NeuroID.shared.datastore.removeSentEvents()
    }

    func testRandom() throws {
        let dictRandom = ["events": "eventstringt", "status": "pending"]
        if let key = dictRandom.first(where: { $0.value == "pending" })?.key {
            NeuroID.shared.logger.log(key)
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
