//
//  EventTests.swift
//  SDKTest
//
//  Created by Clayton Selby on 8/19/21.
//

@testable import NeuroID
import XCTest

class NIDEventTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"
    let userId = "form_mobilesandbox"
    
    override func setUpWithError() throws {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
    }
    
    override func setUp() {
        // Clear out the DataStore Events after each test
        DataStore.removeSentEvents()
        NeuroID.currentScreenName = nil
    }
    
    func initV6BasicTests(
        nidEvent: NIDEvent,
        screenName: String = "",
        eventType: NIDEventName = NIDEventName.blur,
        tgs: String = "",
        tgCount: Int = 1,
        x: CGFloat? = nil,
        y: CGFloat? = nil,
        touchesNil: Bool = true)
    {
        assert(nidEvent.type == eventType.rawValue)

        assert(nidEvent.url == screenName)
        assert(nidEvent.tgs == tgs)
        
        assert(nidEvent.tg != nil)
        assert(nidEvent.tg?.count == tgCount)
        assert(nidEvent.tg?["\(Constants.tgsKey.rawValue)"]?.toString() == tgs)
        
        assert(nidEvent.x == x)
        assert(nidEvent.y == y)
        
        if touchesNil {
            assert(nidEvent.touches == nil)
        } else {
            assert(nidEvent.touches != nil)
        }
    }
    
    func dictionaryTests(dict: [String: Any?], expectedV: String) {
        let actualType = dict["type"] ?? ""
        let actualV = dict["v"] ?? ""
        let actualP = dict["p"] ?? ""
        
        assert(actualType as! String == NIDEventName.blur.rawValue)
        assert(actualV as! String == expectedV)
        assert(actualP as! String? == nil)
    }
    
    func setRtsTests(nidEvent: NIDEvent, rts: String?) {
        assert(nidEvent.type == NIDEventName.blur.rawValue)
        assert(nidEvent.rts == rts)
    }
    
    func testFullPayload() {
        let _ = NeuroID.start()
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
            extraParams: ["sender": TargetValue.string(textfield.nidClassName)])
        
        let touch = NIDEvent(type: .touchStart, tg: tg, view: textfield)
        tracker?.captureEvent(event: touch)
        /// Create Focus event
        let focusBlurEvent = NIDEvent(type: .focus, tg: [
            "\(Constants.tgsKey.rawValue)": TargetValue.string(textfield.id),
        ])
        focusBlurEvent.tgs = TargetValue.string(textfield.id).toString()
        tracker?.captureEvent(event: focusBlurEvent)
        
        /// Input event
        // Create Input
        textfield.text = "text"
        let lengthValue = "\(Constants.eventValuePrefix.rawValue)\(textfield.text?.count ?? 0)"
        let hashValue = textfield.text?.hashValue()
        let inputTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.input, view: textfield, type: "text", attrParams: ["\(Constants.vKey.rawValue)": lengthValue, "\(Constants.hashKey.rawValue)": textfield.text ?? "emptyHash"])
        let inputEvent = NIDEvent(type: NIDEventName.input, tg: inputTG)
        inputEvent.v = lengthValue
        inputEvent.hv = hashValue
        inputEvent.tgs = TargetValue.string(textfield.id).toString()
        tracker?.captureEvent(event: inputEvent)
        
        /// Create Text change and blur
        textfield.text = "text_match"
        let sm = 0.0
        let pd = 0.0
        let textChangeTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.textChange, view: textfield, type: "text", attrParams: ["\(Constants.vKey.rawValue)": lengthValue, "\(Constants.hashKey.rawValue)": textfield.text ?? "emptyHash"])
        
        let textChangeEvent = NIDEvent(type: .textChange)
        textChangeEvent.v = lengthValue
        textChangeEvent.tg = textChangeTG
        textChangeEvent.sm = sm
        textChangeEvent.pd = pd
      
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
            extraParams: ["sender": TargetValue.string(button.nidClassName)])
        
        let touch2 = NIDEvent(type: .touchStart, tg: tg2, view: button)
        tracker?.captureEvent(event: touch2)
        
        /// Get all events
        let events = DataStore.getAllEvents()
        /// Create http request
        let tabId = ParamsCreator.getTabId()
        
        let randomString = UUID().uuidString
        let pageid = randomString.replacingOccurrences(of: "-", with: "").prefix(12)
        
        let neuroHTTPRequest = NeuroHTTPRequest(
            clientID: NeuroID.getClientID(),
            environment: NeuroID.getEnvironment(),
            sdkVersion: ParamsCreator.getSDKVersion(),
            pageTag: NeuroID.getScreenName() ?? "UNKNOWN",
            responseID: ParamsCreator.generateUniqueHexID(),
            siteID: "_",
            linkedSiteId: nil,
            userID: NeuroID.getUserID(),
            registeredUserID: NeuroID.getRegisteredUserID(),
            jsonEvents: events,
            tabID: "\(tabId)",
            pageID: "\(pageid)",
            url: "ios://\(NeuroID.getScreenName() ?? "")")
        /// Transform event into json
        ///
        do {
            let encoder = JSONEncoder()
            let values = try encoder.encode(neuroHTTPRequest)
            let str = String(data: values, encoding: .utf8)
            NIDLog.log(str as Any)
            let filename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("payload.txt")
            NIDLog.log("************\(filename)*************")
            try str?.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            NIDLog.e(error)
        }
        assert(neuroHTTPRequest != nil)
    }
    
    func test_init_1() {
        let nidEvent = NIDEvent(type: .blur)
        
        assert(nidEvent.type == NIDEventName.blur.rawValue)
    }
    
    func test_init_2() {
        let nidEvent = NIDEvent(sessionEvent: NIDSessionEventName.setVariable)
        
        assert(nidEvent.type == NIDSessionEventName.setVariable.rawValue)
    }
    
    func test_init_3() {
        let nidEvent = NIDEvent(rawType: "testRaw")
        
        assert(nidEvent.type == "testRaw")
    }

    func test_init_4() {
        let nidEvent = NIDEvent(session: .createSession)
        
        assert(nidEvent.type == NIDSessionEventName.createSession.rawValue)
        assert(nidEvent.f == nil)
    }
    
    func test_init_4_1() {
        let nidEvent = NIDEvent(
            session: .createSession,
            f: "test1",
            sid: "test2",
            lsid: "test3",
            cid: "test4",
            did: "test5",
            loc: "test6",
            ua: "test7",
            tzo: 0,
            lng: "test8",
            p: "test9",
            dnt: false,
            tch: true,
            pageTag: "testURL",
            ns: "test10",
            jsv: "test11",
            gyro: NIDSensorData(axisX: 0, axisY: 0, axisZ: 0),
            accel: NIDSensorData(axisX: 0, axisY: 0, axisZ: 0),
            rts: "test12",
            sh: 0.1,
            sw: 0.2,
            metadata: NIDMetadata())
        
        assert(nidEvent.type == NIDSessionEventName.createSession.rawValue)
        assert(nidEvent.f == "test1")
        assert(nidEvent.sid == "test2")
        assert(nidEvent.lsid == "test3")
        assert(nidEvent.cid == "test4")
        assert(nidEvent.did == "test5")
        assert(nidEvent.loc == "test6")
        assert(nidEvent.ua == "test7")
        assert(nidEvent.tzo == 0)
        assert(nidEvent.lng == "test8")
        assert(nidEvent.p == "test9")
        assert(nidEvent.dnt == false)
        assert(nidEvent.tch == true)
        assert(nidEvent.url == "testURL")
        assert(nidEvent.ns == "test10")
        assert(nidEvent.jsv == "test11")
        assert(nidEvent.gyro != nil)
        assert(nidEvent.accel != nil)
        assert(nidEvent.rts == "test12")
        assert(nidEvent.sh == 0.1)
        assert(nidEvent.sw == 0.2)
        assert(nidEvent.metadata != nil)
    }
    
    func test_init_5() {
        let nidEvent = NIDEvent(type: .blur, tg: nil)
        
        assert(nidEvent.type == NIDEventName.blur.rawValue)
        assert(nidEvent.tg == nil)
    }
    
    func test_init_5_1() {
        let nidEvent = NIDEvent(
            type: .blur,
            tg: ["foo": TargetValue.string("bar")])
        
        assert(nidEvent.type == NIDEventName.blur.rawValue)
        assert(nidEvent.tg != nil)
        assert(nidEvent.tg?.count == 1)
        assert(nidEvent.tg?["foo"]?.toString() == "bar")
    }
    
    func test_init_6() {
        let screenName = "myTestScreenName"
        NeuroID.currentScreenName = screenName
        let nidEvent = NIDEvent(
            type: .blur,
            tg: nil,
            view: nil)
        
        initV6BasicTests(nidEvent: nidEvent, screenName: screenName)
    }
    
    func test_init_6_1() {
        let screenName = "myTestScreenName"
        NeuroID.currentScreenName = screenName
        let nidEvent = NIDEvent(
            type: .blur,
            tg: ["foo": TargetValue.string("bar")],
            view: nil)
        
        initV6BasicTests(nidEvent: nidEvent, screenName: screenName, tgCount: 2)
        assert(nidEvent.tg?["foo"]?.toString() == "bar")
    }
    
    func test_init_6_2() {
        let uiId = "testUIViewId"
        let uiView = UIView()
        uiView.id = uiId
        
        let screenName = "UIView"
        
        let nidEvent = NIDEvent(
            type: .blur,
            tg: nil,
            view: uiView)
        
        initV6BasicTests(nidEvent: nidEvent, screenName: screenName, tgs: uiId, x: 0.0, y: 0.0)
    }
    
    func test_init_6_2_1() {
        let screenName = "myTestScreenName"
        NeuroID.currentScreenName = screenName
        
        let uiId = "testUIViewId"
        let uiView = UIView()
        uiView.id = uiId
        
        let nidEvent = NIDEvent(
            type: .blur,
            tg: nil,
            view: uiView)
        
        initV6BasicTests(nidEvent: nidEvent, screenName: screenName, tgs: uiId, x: 0.0, y: 0.0)
    }
    
    func test_init_6_3() {
        let nidEvent = NIDEvent(
            type: .touchStart,
            tg: nil,
            view: nil)
        
        initV6BasicTests(nidEvent: nidEvent, eventType: .touchStart, touchesNil: false)
        
        assert(nidEvent.touches?.count == 1)
    }
    
    func test_init_6_3_1() {
        let screenName = "UIView"
        let uiView = UIView()
        
        let nidEvent = NIDEvent(
            type: .touchStart,
            tg: nil,
            view: uiView)
        
        initV6BasicTests(
            nidEvent: nidEvent,
            screenName: screenName,
            eventType: .touchStart,
            tgs: "UIView_UNKNOWN_NO_ID_SET_\(uiView.description.hashValue)",
            touchesNil: false)

        assert(nidEvent.touches?.count == 1)
    }
    
    func test_init_6_3_2() {
        let nidEvent = NIDEvent(
            type: .touchMove,
            tg: nil,
            view: nil)
        
        initV6BasicTests(
            nidEvent: nidEvent,
            eventType: .touchMove,
            touchesNil: false)
    }
    
    func test_init_6_3_3() {
        let nidEvent = NIDEvent(
            type: .touchEnd,
            tg: nil,
            view: nil)
        
        initV6BasicTests(
            nidEvent: nidEvent,
            eventType: .touchEnd,
            touchesNil: false)
    }
    
    func test_init_6_3_4() {
        let nidEvent = NIDEvent(
            type: .touchCancel,
            tg: nil,
            view: nil)
        
        initV6BasicTests(
            nidEvent: nidEvent,
            eventType: .touchCancel,
            touchesNil: false)
    }
    
    func test_asDictionary() {
        let expectedV = "value"
        
        let nidEvent = NIDEvent(type: .blur)
        nidEvent.v = expectedV
        
        let dict = nidEvent.asDictionary
        
        dictionaryTests(dict: dict, expectedV: expectedV)
    }
    
    func test_toDictionary() {
        let expectedV = "value"
        
        let nidEvent = NIDEvent(type: .blur)
        nidEvent.v = expectedV
        
        let dict = nidEvent.toDict()
        
        dictionaryTests(dict: dict, expectedV: expectedV)
    }
    
    func test_setRTS_false() {
        let nidEvent = NIDEvent(type: .blur)
        nidEvent.setRTS()
        
        setRtsTests(nidEvent: nidEvent, rts: nil)
    }
    
    func test_setRTS_false_existing() {
        let nidEvent = NIDEvent(type: .blur)
        nidEvent.rts = "test"
        nidEvent.setRTS()
        
        setRtsTests(nidEvent: nidEvent, rts: "test")
    }
    
    func test_setRTS_true() {
        let nidEvent = NIDEvent(type: .blur)
        nidEvent.setRTS(true)
        
        setRtsTests(nidEvent: nidEvent, rts: "targetInteractionEvent")
    }
    
    func test_copy() {
        let nidEvent = NIDEvent(type: .blur)
        nidEvent.v = "myTestValue"
        
        let copyOf = nidEvent.copy()
        
        nidEvent.v = "myUpdatedTestValue"
        
        assert(nidEvent.type == NIDEventName.blur.rawValue)
        assert(nidEvent.v == "myUpdatedTestValue")
        
        assert(copyOf.type == NIDEventName.blur.rawValue)
        assert(copyOf.v == "myTestValue")
    }
}
