//
//  UtilFunctionsTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 7/27/23.
//

@testable import NeuroID
import XCTest

final class UtilFunctionsTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"
    let userId = "form_mobilesandbox"

    let screenNameValue = "testScreen"
    let guidValue = "\(Constants.attrGuidKey.rawValue)"

    let id = "id"
    let textValue = "text"
    let className = "className"

    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey)
    }

    override func setUp() {
        NeuroID.start()
    }

    override func tearDown() {
        NeuroID.stop()

        // Clear out the DataStore Events after each test
        DataStore.removeSentEvents()
    }

    func getEventOfType(type: String) -> [NIDEvent] {
        let dataStoreEvents = DataStore.getAllEvents()
        return dataStoreEvents.filter { $0.type == type }
    }

    func assertEventTypeCount(type: String, expectedCount: Int) {
        let rEvents = getEventOfType(type: type)
        assert(rEvents.count == expectedCount)
    }

    func test_getFullViewlURLPath_no_view() {
        let expectedValue = screenNameValue

        let value = UtilFunctions.getFullViewlURLPath(currView: nil, screenName: expectedValue)

        assert(value == expectedValue)
    }

    func test_getFullViewlURLPath_no_parent() {
        let expectedValue = screenNameValue
        let uiView = UIView()

        let value = UtilFunctions.getFullViewlURLPath(currView: uiView, screenName: expectedValue)

        assert(value == expectedValue)
    }

    func test_registerField() {
        let expectedValue = 1

        UtilFunctions.registerField(
            textValue: textValue,
            etn: "INPUT",
            id: id,
            className: className,
            type: "BUTTON",
            screenName: "screenName",
            tg: ["string": TargetValue.string("test")],
            attrs: [],
            rts: false,
            rawText: false)

        assertEventTypeCount(type: "REGISTER_TARGET", expectedCount: expectedValue)
    }

    func test_captureContextMenuAction_cut() {
        let expectedValue = 1
        let uiView = UIView()

        UtilFunctions.captureContextMenuAction(
            type: .cut,
            view: uiView,
            text: textValue,
            className: className)

        assertEventTypeCount(type: "CUT", expectedCount: expectedValue)
    }

    func test_captureTextEvents_input() {
        let expectedValue = 1
        let uiView = UIView()

        UtilFunctions.captureTextEvents(
            view: uiView,
            textValue: textValue,
            eventType: .input)

        assertEventTypeCount(type: "INPUT", expectedCount: expectedValue)
    }

    func test_captureTextEvents_focus() {
        let expectedValue = 1
        let uiView = UIView()

        UtilFunctions.captureTextEvents(
            view: uiView,
            textValue: textValue,
            eventType: .focus)

        assertEventTypeCount(type: "FOCUS", expectedCount: expectedValue)
    }

    func test_captureTextEvents_blur() {
        let expectedValue = 1
        let uiView = UIView()

        UtilFunctions.captureTextEvents(
            view: uiView,
            textValue: textValue,
            eventType: .blur)

        assertEventTypeCount(type: "BLUR", expectedCount: expectedValue)
        assertEventTypeCount(type: "TEXT_CHANGE", expectedCount: expectedValue)
    }

    func test_captureInputTextChangeEvent_input() {
        let expectedValue = 1
        let uiView = UIView()

        UtilFunctions.captureInputTextChangeEvent(
            eventType: .input,
            textControl: uiView,
            inputType: "INPUT",
            lengthValue: "4",
            hashValue: "1234",
            attrParams: [:])

        assertEventTypeCount(type: "INPUT", expectedCount: expectedValue)
    }

    func test_captureFocusBlurEvent_focus() {
        let expectedValue = 1

        UtilFunctions.captureFocusBlurEvent(eventType: .focus, id: id)

        assertEventTypeCount(type: "FOCUS", expectedCount: expectedValue)
    }

    func test_captureWindowLoadUnloadEvent_load() {
        let expectedValue = 1

        UtilFunctions.captureWindowLoadUnloadEvent(eventType: .windowLoad, id: id, className: className)

        assertEventTypeCount(type: "WINDOW_LOAD", expectedCount: expectedValue)
    }

    func test_getParentClasses() {
        let expectedValue = "UIView"

        let value = getParentClasses(currView: nil, hierarchyString: nil)

        assert(value == expectedValue)
    }

    func test_getParentClasses_currView() {
        let expectedValue = "UITextView"
        let uiView = UITextView()

        let value = getParentClasses(currView: uiView, hierarchyString: nil)

        assert(value == expectedValue)
    }

    func test_getParentClasses_hierarchyString() {
        let expectedValue = "UIView\\HSTRING"
        let uiView = UIView()

        let value = getParentClasses(currView: uiView, hierarchyString: "HSTRING")

        assert(value == expectedValue)
    }

    func test_getParentClasses_superview() {
        let expectedValue = "UIView\\UITextView\\HSTRING"
        let uiView = UIView()
        let child = UITextView()

        uiView.addSubview(child)

        let value = getParentClasses(currView: child, hierarchyString: "HSTRING")

        assert(value == expectedValue)
    }
}
