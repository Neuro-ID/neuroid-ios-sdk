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
    
    let logger = NIDLog()
    
    override func setUpWithError() throws {
        _ = NeuroID.configure(clientKey: clientKey, isAdvancedDevice: false)
    }
    
    override func setUp() {
        // Clear out the DataStore Events after each test
        NeuroID.datastore.removeSentEvents()
        NeuroID.currentScreenName = nil
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
        NeuroID._isSDKStarted = true
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
        var tg = ParamsCreator.getTgParams(
            view: textfield,
            extraParams: ["sender": TargetValue.string(textfield.nidClassName)])
        
        let viewId = TargetValue.string(textfield.id)
        tg["\(Constants.tgsKey.rawValue)"] = viewId
        
        tracker?.captureEvent(event: NIDEvent(
            type: .touchStart,
            tg: tg,
            tgs: viewId.toString(),
            x: textfield.frame.origin.x,
            y: textfield.frame.origin.y,
            url: UtilFunctions.getFullViewlURLPath(
                currView: textfield
            )))
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
        var tg2 = ParamsCreator.getTgParams(
            view: button,
            extraParams: ["sender": TargetValue.string(button.nidClassName)])
        
        let viewId2 = TargetValue.string(button.id)
        tg2["\(Constants.tgsKey.rawValue)"] = viewId2

        tracker?.captureEvent(event: NIDEvent(
            type: .touchStart,
            tg: tg2,
            tgs: viewId2.toString(),
            x: button.frame.origin.x,
            y: button.frame.origin.y,
            url: UtilFunctions.getFullViewlURLPath(
                currView: button
            )))
        
        /// Get all events
        let events = NeuroID.datastore.getAllEvents()
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
            linkedSiteID: nil,
            sessionID: NeuroID.getSessionID(),
            registeredUserID: NeuroID.getRegisteredUserID(),
            jsonEvents: events,
            tabID: "\(tabId)",
            pageID: "\(pageid)",
            url: "ios://\(NeuroID.getScreenName() ?? "")",
            packetNumber: 0)
        /// Transform event into json
        ///
        do {
            let encoder = JSONEncoder()
            let values = try encoder.encode(neuroHTTPRequest)
            let str = String(data: values, encoding: .utf8)
            logger.log("\(String(describing: str))")
            let filename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("payload.txt")
            logger.log("************\(filename)*************")
            try str?.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            logger.e("\(error.localizedDescription)")
        }
        assert(neuroHTTPRequest != nil)
    }
    
    func test_init_1() {
        let nidEvent = NIDEvent(type: .blur)
        
        assert(nidEvent.type == NIDEventName.blur.rawValue)
    }
    
    func test_init_3() {
        let nidEvent = NIDEvent(rawType: "testRaw")
        
        assert(nidEvent.type == "testRaw")
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
