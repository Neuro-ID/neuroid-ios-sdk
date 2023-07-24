//
//  EventTests.swift
//  SDKTest
//
//  Created by Clayton Selby on 8/19/21.
//

@testable import NeuroID
import XCTest

class EventTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"
    let userId = "form_mobilesandbox"
    
    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey)
    }
    
    override func setUp() {
        // Clear out the DataStore Events after each test
        DataStore.removeSentEvents()
    }
    
    func testSetScreeName() {
        try? NeuroID.setScreenName(screen: "WOW")
        assert(NeuroID.getScreenName() == "WOW")
    }
    
    func testInvalidScreenName() {
        try? NeuroID.setScreenName(screen: "WOW A SPACE")
        assert(NeuroID.getScreenName() == "WOW%20A%20SPACE")
    }

    func testLocale() {
        print("Locale: ", ParamsCreator.getLocale())
        XCTAssertTrue(ParamsCreator.getLocale() != nil)
    }
    
    func testUserAgent() {
        let data = ParamsCreator.getUserAgent()
        print("User Agent: ", data)
        XCTAssertTrue(data != nil)
    }

    func testSessionExpired() {
        let data = ParamsCreator.isSessionExpired()
        XCTAssertTrue(true)
    }
    
    func testSettingAndGettingAPIClientKey() {
        let keyLookup = NeuroID.getClientKeyFromLocalStorage()
        print("Key lookup:", keyLookup)
        XCTAssertTrue(keyLookup == clientKey)
    }
    
    func testGetTimeStamp() {
        let data = ParamsCreator.getTimeStamp()
        print("Timestamp: ", data)
        XCTAssertTrue(data != nil)
    }

    func testTimeZoneOffset() {
        let data = ParamsCreator.getTimezone()
        print("TimeZone Offset: ", data)
        XCTAssertTrue(data != nil)
    }
    
    func testLanguage() {
        let data = ParamsCreator.getLanguage()
        print("Language: ", data)
        XCTAssertTrue(data != nil)
    }
    
    func testPlatform() {
        let data = ParamsCreator.getPlatform()
        print("Platform: ", data)
        XCTAssertTrue(data != nil)
    }
    
    func testDnt() {
        let data = ParamsCreator.getDnt()
        print("Dnt: ", data)
        XCTAssertTrue(data != nil)
    }
    
    func testTouch() {
        let data = ParamsCreator.getTouch()
        print("Touch: ", data)
        XCTAssertTrue(data != nil)
    }
    
    func testGetBaseURL() {
        let data = NeuroID.getCollectionEndpointURL()
        print("URL: ", data)
        XCTAssertTrue(data != nil)
    }
    
    func testSDKVersion() {
        let data = ParamsCreator.getSDKVersion()
        print("Version: ", data)
        XCTAssertTrue(data != nil)
    }
    
    func testCommandQueueNameSpace() {
        let data = ParamsCreator.getCommandQueueNamespace()
        print("Namespace: ", data)
        XCTAssertTrue(data != nil)
    }
    
    func testStoppingSDKIsStoppedFalse() {
        if NeuroID.isStopped() {
            NeuroID.start()
        }
        let isStopped = NeuroID.isStopped()
        print("Is Stopped", isStopped)
        XCTAssertTrue(!isStopped)
    }
    
    func testStoppingSDKIsStoppedTrue() {
        NeuroID.stop()
        let isStopped = NeuroID.isStopped()
        print("Is Stopped", isStopped)
        XCTAssertTrue(isStopped)
    }
    
    func testSetIUserID() {
        try? NeuroID.setUserID("atestUserID")
        let params = ParamsCreator.getDefaultSessionParams()
        let uid = params["userId"] as! String
        XCTAssert(uid == "atestUserID")
    }

    func testEventParams() throws {
//        let urlName = "HomeScreen"
//        let tracker = NeuroIDTracker(userUrl: urlName)
        let urlName = "HomeScreen"
        let testView = UIViewController()
        let userID = "atestUserID"
        let _ = NeuroIDTracker(screen: urlName, controller: testView)
//        let params = ParamsCreator.getDefaultSessionParams();
        try? NeuroID.setUserID(userID)
//        let copyEvent = NIDEvent(type: .copy, tg: ["et": "fieldset"], x: 10, y: 10)
        let params = ParamsCreator.getDefaultSessionParams()
        //        let params = tracker.getEventParams(event: copyEvent, userUrl: urlName)

        print("EVENT: ", params)
        XCTAssertTrue(params["environment"] != nil)

        XCTAssertTrue(params["sdkVersion"] != nil)

        XCTAssertTrue(params["responseId"] != nil)
        XCTAssertTrue(params["userId"] as! String == userID)

//        XCTAssertTrue(params["events"] != nil)
//        XCTAssertTrue(params["events"] is [String: Any])
//        let events = params["events"] as! [String: Any]
//        XCTAssertTrue(events["type"] as! String == "COPY")
//        XCTAssertTrue(events["x"] as! Int == 10)
//        XCTAssertTrue(events["y"] as! Int == 10)
    }
    
    func testEventSubmitForm() {
        let event = NeuroID.formSubmit()
        XCTAssertTrue(event.type == NIDEventName.applicationSubmit.rawValue)
    }
    
    func testEventSubmitFormFailure() {
        let event = NeuroID.formSubmitFailure()
        XCTAssertTrue(event.type == NIDEventName.applicationSubmitFailure.rawValue)
    }
    
    func testEventSubmitFormSuccess() {
        let event = NeuroID.formSubmitSuccess()
        XCTAssertTrue(event.type == NIDEventName.applicationSubmitSuccess.rawValue)
    }
    
    func testEventSetVariable() {
        let event = NeuroID.setCustomVariable(key: "test", v: "test2")
        XCTAssertTrue(event.type == NIDSessionEventName.setVariable.rawValue)
    }
    
    func testLateRegistration() {
        let view = UITextView()
        view.id = "myTextView"
        let view2 = UITextView()
        view2.id = "myTextView2"
        XCTAssertTrue(NeuroIDTracker.registerViewIfNotRegistered(view: view))
        
        // Ensure we dont re-add it
        XCTAssertFalse(NeuroIDTracker.registerViewIfNotRegistered(view: view))
    }

    func testCalcSimilarity() {
        let urlName = "HomeScreen"
        let testView = UIViewController()
        if NeuroID.isStopped() {
            NeuroID.start()
        }

        let tracker = NeuroIDTracker(screen: urlName, controller: testView)
        let similarityLonger = tracker.calcSimilarity(previousValue: "alat", currentValue: "zlata")
        print("Close Similarity \(similarityLonger)")
        XCTAssertTrue(similarityLonger == 0.6)
        
        let similarityShorter = tracker.calcSimilarity(previousValue: "amuchlongerdiffere", currentValue: "wowshort")
        print("Much different Similarity \(similarityShorter)")
        XCTAssertTrue(similarityLonger == 0.6)
    }
    
    func testpercentageDifference() {
        let urlName = "HomeScreen"
        let testView = UIViewController()
        if NeuroID.isStopped() {
            NeuroID.start()
        }

        let tracker = NeuroIDTracker(screen: urlName, controller: testView)
        let percentDiff = tracker.percentageDifference(newNumOrig: "20", originalNumOrig: "30")
        print("Percentdiff \(percentDiff)")
    }
    
    func testExcludeByStringID() {
        NeuroID.excludeViewByTestID(excludedView: "DontTrackMeID")
        assert(NeuroID.excludedViewsTestIDs.contains(where: { $0 == "DontTrackMeID" }))
    }
    
    func testSha256Salt() {
        let myTestString = "test"
        let hash = myTestString.sha256()
        print("Raw hash \(hash)")
        print("Prefixed hash \(hash.prefix(8))")
        assert(!hash.prefix(8).isEmpty)
    }
    
    func testCloseSession() {
        do {
            NeuroID.start()
            let closeSession = try NeuroID.closeSession()
            XCTAssertTrue(NeuroID.isStopped())
            assert(closeSession.ct == "SDK_EVENT")
        } catch {
            XCTFail()
        }
    }
     
    func testManuallyTargetRegister() {
        NeuroID.start()
        let testView = UITextView()
        testView.id = "wow"
        NeuroID.manuallyRegisterTarget(view: testView)
        let events = DataStore.getAllEvents()
        let registeredTargetEvents = events.filter { $0.type == "REGISTER_TARGET" }
        let validEvent = registeredTargetEvents.filter { $0.tgs == "wow" }
        assert(validEvent.count == 1)
        assert(validEvent[0].et == "UITextView::UITextView")
    }
    
    func testRNManuallyTargetRegister() {
        NeuroID.start()
        let testView = UITextView()
        testView.id = "wow"
        let event = NeuroID.manuallyRegisterRNTarget(id: "WOW2", className: "UITextView", screenName: "HOME", placeHolder: "name here")
        let events = DataStore.getAllEvents()
//        let validEvent = events.filter { $0.type == "REGISTER_TARGET" }
        assert(event.etn == "INPUT")
    }

    func testFullPayload() {
        NeuroID.start()
        var tracker: NeuroIDTracker?
        /// Create a textfield
        lazy var textfield: UITextField = {
            let textfield = UITextField(frame: CGRect(x: 100, y: 100, width: 100, height: 20))
            textfield.id = "MainTextfield"
            return textfield
        }()
        lazy var button: UIButton = {
            let button = UIButton(frame: CGRect(x: 150, y: 100, width: 100, height: 20))
            button.id = "Button"
            return button
        }()
        /// Create UIViewcontroller
        let viewController: UIViewController = {
            let viewController = UIViewController()
            tracker = NeuroIDTracker(screen: "MainController", controller: viewController)
            return viewController
        }()
        viewController.view.addSubview(textfield)
        viewController.view.addSubview(button)
        NeuroID.manuallyRegisterTarget(view: textfield)
        NeuroID.manuallyRegisterTarget(view: button)
        /// Create touch event
        let tg = ParamsCreator.getTgParams(
            view: textfield,
            extraParams: ["sender": TargetValue.string(textfield.className)])

        let touch = NIDEvent(type: .touchStart, tg: tg, view: textfield)
        tracker?.captureEvent(event: touch)
        /// Create Focus event
        var focusBlurEvent = NIDEvent(type: .focus, tg: [
            "tgs": TargetValue.string(textfield.id),
        ])
        focusBlurEvent.tgs = TargetValue.string(textfield.id).toString()
        tracker?.captureEvent(event: focusBlurEvent)
        
        /// Input event
        // Create Input
        textfield.text = "text"
        let lengthValue = "\(Constants.eventValuePrefix.rawValue)\(textfield.text?.count ?? 0)"
        let hashValue = textfield.text?.hashValue()
        let inputTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.input, view: textfield, type: "text", attrParams: ["v": lengthValue, "hash": textfield.text ?? "emptyHash"])
        var inputEvent = NIDEvent(type: NIDEventName.input, tg: inputTG)
        inputEvent.v = lengthValue
        inputEvent.hv = hashValue
        inputEvent.tgs = TargetValue.string(textfield.id).toString()
        tracker?.captureEvent(event: inputEvent)
        
        /// Create Text change and blur
        textfield.text = "text_match"
        let sm = tracker?.calcSimilarity(previousValue: "text", currentValue: "text_match") ?? 0
        let pd = tracker?.percentageDifference(newNumOrig: "text", originalNumOrig: "text_match") ?? 0
        let textChangeTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.textChange, view: textfield, type: "text", attrParams: ["v": lengthValue, "hash": textfield.text ?? "emptyHash"])
        var textChangeEvent = NIDEvent(type: NIDEventName.textChange, tg: textChangeTG, sm: sm, pd: pd)
        textChangeEvent.v = lengthValue
        var shaText = textfield.text ?? ""
        if shaText != "" {
            shaText = shaText.hashValue()
        }
        textChangeEvent.hv = shaText
        textChangeEvent.tgs = TargetValue.string(textfield.id).toString()
        tracker?.captureEvent(event: textChangeEvent)
        
        /// Touch a button
        let tg2 = ParamsCreator.getTgParams(
            view: button,
            extraParams: ["sender": TargetValue.string(button.className)])

        let touch2 = NIDEvent(type: .touchStart, tg: tg2, view: button)
        tracker?.captureEvent(event: touch2)
        
        /// Get all events
        let events = DataStore.getAllEvents()
        /// Create http request
        let tabId = ParamsCreator.getTabId()
        
        let randomString = UUID().uuidString
        let pageid = randomString.replacingOccurrences(of: "-", with: "").prefix(12)
        
        let neuroHTTPRequest = NeuroHTTPRequest(clientId: ParamsCreator.getClientId(), environment: NeuroID.getEnvironment(), sdkVersion: ParamsCreator.getSDKVersion(), pageTag: NeuroID.getScreenName() ?? "UNKNOWN", responseId: ParamsCreator.generateUniqueHexId(), siteId: "_", userId: ParamsCreator.getUserID() ?? "", jsonEvents: events, tabId: "\(tabId)", pageId: "\(pageid)", url: "ios://\(NeuroID.getScreenName() ?? "")")
        /// Transform event into json
        do {
            let encoder = JSONEncoder()
            let values = try encoder.encode(neuroHTTPRequest)
            let str = String(data: values, encoding: .utf8)
            print(str as Any)
            let filename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("payload.txt")
            print("************\(filename)*************")
            try str?.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print(error)
        }
        assert(neuroHTTPRequest != nil)
    }
    
    // Specific UI Class Registration Tests
    func testUITextFieldRegistration() {
        NeuroID.start()
        let testView = UITextField()
        testView.id = "UITextField"
        NeuroID.manuallyRegisterTarget(view: testView)
        let events = DataStore.getAllEvents()
        let filteredRegisteredTargets = events.filter { $0.type == "REGISTER_TARGET" }
        assert(filteredRegisteredTargets.count == 1)
        assert(filteredRegisteredTargets[0].et == "UITextField::UITextField")
    }
    
    func testUITextViewRegistration() {
        NeuroID.start()
        let testView = UITextView()
        testView.id = "UITextView"
        NeuroID.manuallyRegisterTarget(view: testView)
        let events = DataStore.getAllEvents()
        let filteredRegisteredTargets = events.filter { $0.type == "REGISTER_TARGET" }
        assert(filteredRegisteredTargets.count == 1)
        assert(filteredRegisteredTargets[0].et == "UITextView::UITextView")
    }
    
    func testUIButtonRegistration() {
        NeuroID.start()
        let testView = UIButton()
        testView.id = "UIButton"
        NeuroID.manuallyRegisterTarget(view: testView)
        let events = DataStore.getAllEvents()
        let filteredRegisteredTargets = events.filter { $0.type == "REGISTER_TARGET" }
        assert(filteredRegisteredTargets.count == 1)
        assert(filteredRegisteredTargets[0].et == "UIButton::UIButton")
    }
    
    func testUIDatePickerRegistration() {
        NeuroID.start()
        let testView = UIDatePicker()
        testView.id = "UIDatePicker"
        NeuroID.manuallyRegisterTarget(view: testView)
        let events = DataStore.getAllEvents()
        let filteredRegisteredTargets = events.filter { $0.type == "REGISTER_TARGET" }
        assert(filteredRegisteredTargets.count == 1)
        assert(filteredRegisteredTargets[0].et == "UIDatePicker::UIDatePicker")
    }
    
    // UI Class Registrations that are NOT implemented
    func testUISliderNotRegistered() {
        NeuroID.start()
        let testView = UISlider()
        testView.id = "UISlider"
        NeuroID.manuallyRegisterTarget(view: testView)
        let events = DataStore.getAllEvents()
        let filteredRegisteredTargets = events.filter { $0.type == "REGISTER_TARGET" }
        assert(filteredRegisteredTargets.count == 0)
    }
    
    func testUISwitchNotRegistered() {
        NeuroID.start()
        let testView = UISwitch()
        testView.id = "UISwitch"
        NeuroID.manuallyRegisterTarget(view: testView)
        let events = DataStore.getAllEvents()
        let filteredRegisteredTargets = events.filter { $0.type == "REGISTER_TARGET" }
        assert(filteredRegisteredTargets.count == 0)
    }
    
    func testUITableViewCellNotRegistered() {
        NeuroID.start()
        let testView = UITableViewCell()
        testView.id = "UITableViewCell"
        NeuroID.manuallyRegisterTarget(view: testView)
        let events = DataStore.getAllEvents()
        let filteredRegisteredTargets = events.filter { $0.type == "REGISTER_TARGET" }
        assert(filteredRegisteredTargets.count == 0)
    }
    
    func testUIPickerViewNotRegistered() {
        NeuroID.start()
        let testView = UIPickerView()
        testView.id = "UIPickerView"
        NeuroID.manuallyRegisterTarget(view: testView)
        let events = DataStore.getAllEvents()
        let filteredRegisteredTargets = events.filter { $0.type == "REGISTER_TARGET" }
        assert(filteredRegisteredTargets.count == 0)
    }
}
