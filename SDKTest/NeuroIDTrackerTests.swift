//
//  NeuroIDTrackerTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 3/30/23.
//

@testable import NeuroID
import XCTest

class NeuroIDTrackerTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"
    let userId = "form_mobilesandbox"
    
    let screenNameValue = "testScreen"
    let guidValue = "\(Constants.attrGuidKey.rawValue)"
    
    override func setUpWithError() throws {
        NeuroID.captureGyroCadence = false
        _ = NeuroID.configure(clientKey: clientKey)
    }
    
    override func setUp() {
          _ = NeuroID.start()
    }
    
    override func tearDown() {
        _ = NeuroID.stop()
        
        // Clear out the DataStore Events after each test
        DataStore.removeSentEvents()
    }
    
    func sleep(timeout: Double) {
        let sleep = expectation(description: "Wait \(timeout) seconds.")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeout) {
            sleep.fulfill()
        }
        wait(for: [sleep], timeout: timeout + 1)
    }
    
    func assertEventTypeCountFromArray(type: String, expectedCount: Int, events: [NIDEvent]) {
        let dataStoreEvents = events
        let filteredEvents = dataStoreEvents.filter { $0.type == type }
        
        assert(filteredEvents.count == expectedCount)
    }
    
    func assertEventTypeCount(type: String, expectedCount: Int) -> [NIDEvent] {
        let dataStoreEvents = DataStore.getAllEvents()
        let filteredEvents = dataStoreEvents.filter { $0.type == type }
        
        assert(filteredEvents.count == expectedCount)
        
        return filteredEvents
    }
    
    func assertViewRegistered(v: UIView) {
        let filteredEvent = assertEventTypeCount(type: "REGISTER_TARGET", expectedCount: 1)
        
        let firstEvent = filteredEvent[0]
        assert(firstEvent.type == "REGISTER_TARGET")
        assert((firstEvent.tgs?.contains("\(v.nidClassName)_UNKNOWN_NO_ID_SET")) != nil)
    }
    
    func assertViewNOTRegistered(v: UIView) {
        let dataStoreEvents = DataStore.getAllEvents()
        let filteredEvent = dataStoreEvents.filter { $0.type == "REGISTER_TARGET" }
        assert(filteredEvent.count == 0)
        
        let _ = assertEventTypeCount(type: "REGISTER_TARGET", expectedCount: 0)
    }
    
    func assertViewWithIdRegistered(v: UIView, id: String) {
        let filteredEvent = assertEventTypeCount(type: "REGISTER_TARGET", expectedCount: 1)
        
        let firstEvent = filteredEvent[0]
        assert(firstEvent.type == "REGISTER_TARGET")
        assert((firstEvent.tgs?.contains("\(id)")) != nil)
    }
    
    func assertActionExists(target: UIControl, actionParent: NeuroIDTracker, actionType: UIControl.Event, actionName: String) {
        let actionQuery = target.actions(forTarget: actionParent, forControlEvent: actionType)
        XCTAssertNotNil(actionQuery, "No actions found for \(actionType) event")
        XCTAssertEqual(actionQuery?.first, actionName, "Action \(actionName) not found")
        assert(actionQuery?.count == 1)
    }
    
    func test_captureEvent() {
        let tracker = NeuroIDTracker(screen: screenNameValue, controller: nil)
        let event = NIDEvent(type: .keyUp)
        
        tracker.captureEvent(event: event)
        
        let _ = assertEventTypeCount(type: "KEY_UP", expectedCount: 1)
        
//         NOT WORKING?
//        assert(filteredEvent[0].url ?? "" == "testScreen")
    }
    
    func test_captureEvent_stopped() {
        let tracker = NeuroIDTracker(screen: screenNameValue, controller: nil)
        let event = NIDEvent(type: .keyUp)
        
        _ = NeuroID.stop()
        tracker.captureEvent(event: event)

        let _ = assertEventTypeCount(type: "KEY_UP", expectedCount: 0)
        
//         NOT WORKING?
//        assert(filteredEvent[0].url ?? "" == "testScreen")
    }
    
    func test_registerSingleView_UITextField() {
        let uiView = UITextField()
        
        NeuroIDTracker.registerSingleView(v: uiView, screenName: screenNameValue, guid: guidValue)
        
        assertViewRegistered(v: uiView)
    }
    
    func test_registerSingleView_UITextView() {
        let uiView = UITextView()
        
        NeuroIDTracker.registerSingleView(v: uiView, screenName: screenNameValue, guid: guidValue)
        
        assertViewRegistered(v: uiView)
    }
    
    func test_registerSingleView_UIButton() {
        let uiView = UIButton()
        
        NeuroIDTracker.registerSingleView(v: uiView, screenName: screenNameValue, guid: guidValue)
        
        assertViewRegistered(v: uiView)
    }
    
    func test_registerSingleView_UISlider() {
        let uiView = UISlider()
        
        NeuroIDTracker.registerSingleView(v: uiView, screenName: screenNameValue, guid: guidValue)
        
        assertViewRegistered(v: uiView)
    }
    
    func test_registerSingleView_UISwitch() {
        let uiView = UISwitch()
        
        NeuroIDTracker.registerSingleView(v: uiView, screenName: screenNameValue, guid: guidValue)
        
        assertViewRegistered(v: uiView)
    }
    
    func test_registerSingleView_UIDatePicker() {
        let uiView = UIDatePicker()
        
        NeuroIDTracker.registerSingleView(v: uiView, screenName: screenNameValue, guid: guidValue)
        
        assertViewRegistered(v: uiView)
    }
    
    func test_registerSingleView_UIStepper() {
        let uiView = UIStepper()
        
        NeuroIDTracker.registerSingleView(v: uiView, screenName: screenNameValue, guid: guidValue)
        
        assertViewRegistered(v: uiView)
        
        // TO-DO - see why UIButtons are registering in tests
    }
    
    func test_registerSingleView_UISegmentedControl() {
        let uiView = UISegmentedControl()
        
        NeuroIDTracker.registerSingleView(v: uiView, screenName: screenNameValue, guid: guidValue)
        
        assertViewRegistered(v: uiView)
    }
    
    func test_registerSingleView_NOT_UIPickerView() {
        let uiView = UIPickerView()
        
        NeuroIDTracker.registerSingleView(v: uiView, screenName: screenNameValue, guid: guidValue)
        
        assertViewNOTRegistered(v: uiView)
    }
    
    func test_registerSingleView_NOT_UITableViewCell() {
        let uiView = UITableViewCell()
        
        NeuroIDTracker.registerSingleView(v: uiView, screenName: screenNameValue, guid: guidValue)
        
        assertViewNOTRegistered(v: uiView)
    }
    
    func test_registerSingleView_NOT_UIScrollView() {
        let uiView = UIScrollView()
        
        NeuroIDTracker.registerSingleView(v: uiView, screenName: screenNameValue, guid: guidValue)
        
        assertViewNOTRegistered(v: uiView)
    }
    
    func test_subscribe() {
        NeuroID.observingInputs = false
        
        let uiControllerBasic = UIViewController()
        let input = UITextField()

        uiControllerBasic.view.addSubview(input)
        
        // subscribe happens in the INIT method
        let tracker = NeuroIDTracker(
            screen: "test",
            controller: uiControllerBasic
        )
        
        // Text Field Notification Tests - observeTextInputEvents()
        // Field Focus
        let _ = DataStore.getAndRemoveAllEvents()
        NotificationCenter.default.post(name: UITextField.textDidBeginEditingNotification, object: input)
        var e = DataStore.getAndRemoveAllEvents()
        assertEventTypeCountFromArray(type: "REGISTER_TARGET", expectedCount: 1, events: e) // because not registered from view
        assertEventTypeCountFromArray(type: "FOCUS", expectedCount: 1, events: e)
        
        // Field Input
        NotificationCenter.default.post(name: UITextField.textDidChangeNotification, object: input)
        e = DataStore.getAndRemoveAllEvents()
        assertEventTypeCountFromArray(type: "INPUT", expectedCount: 1, events: e)

        // Field Blur
        NotificationCenter.default.post(name: UITextField.textDidEndEditingNotification, object: input)
        e = DataStore.getAndRemoveAllEvents()
        assertEventTypeCountFromArray(type: "BLUR", expectedCount: 1, events: e)
        assertEventTypeCountFromArray(type: "TEXT_CHANGE", expectedCount: 1, events: e)
        
        // App Notification Tests - observeAppEvents()
        NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification, object: UIDevice.self)
        e = DataStore.getAndRemoveAllEvents()
        assertEventTypeCountFromArray(type: "DEVICE_ORIENTATION", expectedCount: 1, events: e)
        assertEventTypeCountFromArray(type: "WINDOW_ORIENTATION_CHANGE", expectedCount: 1, events: e)
        
        // Device Notification Tests - observeRotation()
        if #available(iOS 13.0, *) {
            NotificationCenter.default.post(name: UIScene.didActivateNotification, object: UIScene.self)
            e = DataStore.getAndRemoveAllEvents()
            assertEventTypeCountFromArray(type: "WINDOW_FOCUS", expectedCount: 1, events: e)
            
            NotificationCenter.default.post(name: UIScene.willDeactivateNotification, object: UIScene.self)
            e = DataStore.getAndRemoveAllEvents()
            assertEventTypeCountFromArray(type: "WINDOW_BLUR", expectedCount: 1, events: e)
        } else {
            NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: UIApplication.self)
            e = DataStore.getAndRemoveAllEvents()
            assertEventTypeCountFromArray(type: "WINDOW_FOCUS", expectedCount: 1, events: e)
            
            NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: UIApplication.self)
            e = DataStore.getAndRemoveAllEvents()
            assertEventTypeCountFromArray(type: "WINDOW_BLUR", expectedCount: 1, events: e)
        }
    }
    
    func test_observeViews() {
        let tracker = NeuroIDTracker(
            screen: "test",
            controller: nil
        )

        let button = UIButton(type: .system)
        
        tracker.observeViews([button])
        
        assertActionExists(
            target: button,
            actionParent: tracker,
            actionType: .touchDown,
            actionName: "controlTouchStartWithSender:"
        )
        
        assertActionExists(
            target: button,
            actionParent: tracker,
            actionType: .touchUpInside,
            actionName: "controlTouchEndWithSender:"
        )
        
        assertActionExists(
            target: button,
            actionParent: tracker,
            actionType: .touchUpOutside,
            actionName: "controlTouchMoveWithSender:"
        )
        
        assertActionExists(
            target: button,
            actionParent: tracker,
            actionType: .valueChanged,
            actionName: "valueChangedWithSender:"
        )
    }
    
    func test_registerViewIfNotRegistered() {
        let view = UITextView()
        view.id = "myTextView"
        
        let registerView = NeuroIDTracker.registerViewIfNotRegistered(view: view)
        XCTAssertTrue(registerView)
        assertViewWithIdRegistered(v: view, id: "myTextView")
        
        // Ensure we dont re-add it
        let duplicateRegister = NeuroIDTracker.registerViewIfNotRegistered(view: view)
        XCTAssertFalse(duplicateRegister)
        
        // Assert still only 1 registration
        assertViewWithIdRegistered(v: view, id: "myTextView")
    }
}
