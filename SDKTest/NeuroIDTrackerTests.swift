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
    let guidValue = "guid"
    
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
    
    func assertViewRegistered(v: UIView) {
        let dataStoreEvents = DataStore.getAllEvents()
        let filteredEvent = dataStoreEvents.filter { $0.type == "REGISTER_TARGET" }
        assert(filteredEvent.count == 1)
        
        let firstEvent = filteredEvent[0]
        assert(firstEvent.type == "REGISTER_TARGET")
        assert((firstEvent.tgs?.contains("\(v.className)_UNKNOWN_NO_ID_SET")) != nil)
    }
    
    func assertViewNOTRegistered(v: UIView) {
        let dataStoreEvents = DataStore.getAllEvents()
        let filteredEvent = dataStoreEvents.filter { $0.type == "REGISTER_TARGET" }
        assert(filteredEvent.count == 0)
    }
    
    func test_captureEvent() {
        let tracker = NeuroIDTracker(screen: screenNameValue, controller: nil)
        let event = NIDEvent(type: .keyUp)
        
        tracker.captureEvent(event: event)
        
        let dataStoreEvents = DataStore.getAllEvents()
        let filteredEvent = dataStoreEvents.filter { $0.type == "KEY_UP" }
        
        assert(filteredEvent.count == 1)
//         NOT WORKING?
//        assert(filteredEvent[0].url ?? "" == "testScreen")
    }
    
    func test_captureEvent_stopped() {
        let tracker = NeuroIDTracker(screen: screenNameValue, controller: nil)
        let event = NIDEvent(type: .keyUp)
        
        NeuroID.stop()
        tracker.captureEvent(event: event)
        
        let dataStoreEvents = DataStore.getAllEvents()
        let filteredEvent = dataStoreEvents.filter { $0.type == "KEY_UP" }
        
        assert(filteredEvent.count == 0)
//         NOT WORKING?
//        assert(filteredEvent[0].url ?? "" == "testScreen")
    }
    
    func test_getCurrentSession() {
        let tracker = NeuroIDTracker(screen: screenNameValue, controller: nil)
        
        let sid = tracker.getCurrentSession()
        
        assert(sid != nil)
    }
    
    func test_getCurrentSession_clear_nil() {
        let tracker = NeuroIDTracker(screen: screenNameValue, controller: nil)
        
        NeuroID.clearSession()
        
        let sid = tracker.getCurrentSession()
        
        assert(sid == nil)
    }
    
    func test_getCurrentSession_nil() {
        let tracker = NeuroIDTracker(screen: screenNameValue, controller: nil)

        UserDefaults.standard.setValue(nil, forKey: "nid_sid")
        
        let sid = tracker.getCurrentSession()
        
        assert(sid == nil)
    }
    
    func test_getFullViewlURLPath_no_view() {
        let expectedValue = screenNameValue
        
        let value = NeuroIDTracker.getFullViewlURLPath(currView: nil, screenName: expectedValue)
        
        assert(value == expectedValue)
    }
    
    func test_getFullViewlURLPath_no_parent() {
        let expectedValue = screenNameValue
        let uiView = UIView()
        
        let value = NeuroIDTracker.getFullViewlURLPath(currView: uiView, screenName: expectedValue)
        
        assert(value == expectedValue)
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
    
    func test_registerSingleView_UIDatePicker() {
        let uiView = UIDatePicker()
        
        NeuroIDTracker.registerSingleView(v: uiView, screenName: screenNameValue, guid: guidValue)
        
        assertViewRegistered(v: uiView)
    }
    
    func test_registerSingleView_NOT_UISlider() {
        let uiView = UISlider()
        
        NeuroIDTracker.registerSingleView(v: uiView, screenName: screenNameValue, guid: guidValue)
        
        assertViewNOTRegistered(v: uiView)
    }
    
    func test_registerSingleView_NOT_UISwitch() {
        let uiView = UISwitch()
        
        NeuroIDTracker.registerSingleView(v: uiView, screenName: screenNameValue, guid: guidValue)
        
        assertViewNOTRegistered(v: uiView)
    }
    
    func test_registerSingleView_NOT_UITableViewCell() {
        let uiView = UITableViewCell()
        
        NeuroIDTracker.registerSingleView(v: uiView, screenName: screenNameValue, guid: guidValue)
        
        assertViewNOTRegistered(v: uiView)
    }
    
    func test_registerSingleView_NOT_UIPickerView() {
        let uiView = UIPickerView()
        
        NeuroIDTracker.registerSingleView(v: uiView, screenName: screenNameValue, guid: guidValue)
        
        assertViewNOTRegistered(v: uiView)
    }
    
//    Unsure how to test the following
//    subscribe
//    observeViews
}
