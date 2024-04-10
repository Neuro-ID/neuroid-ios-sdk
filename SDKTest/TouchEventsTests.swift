//
//  TrackerEventsTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 9/1/23.
//

@testable import NeuroID
import XCTest

class TouchEventTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"

    override func setUpWithError() throws {
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

    func assertEventTypeCount(type: String, expectedCount: Int) {
        let dataStoreEvents = DataStore.getAllEvents()
        let filteredEvents = dataStoreEvents.filter { $0.type == type }

        assert(filteredEvents.count == expectedCount)
    }

    func test_captureTouchInfo() {
        let view = UITextView()
        let gesture = UITapGestureRecognizer(target: view, action: #selector(view.handleDoubleTap))

        // Create a Set to hold mock UITouch objects
        var mockTouches = Set<UITouch>()

        // Create and configure mock UITouch objects
        let mockLocation = CGPoint(x: 100, y: 100)
        let mockTimestamp = Date().timeIntervalSinceReferenceDate
        let mockTouch = UITouch()
        mockTouch.setValue(mockLocation, forKey: "locationInWindow")
        mockTouch.setValue(mockTimestamp, forKey: "timestamp")

        // Add mock UITouch objects to the Set
        mockTouches.insert(mockTouch)

        captureTouchInfo(
            gesture: gesture,
            touches: mockTouches,
            type: .touchStart)

        assertEventTypeCount(type: NIDEventName.touchStart.rawValue, expectedCount: 1)
    }

    func test_captureTouchEvent() {
        captureTouchEvent(type: .touchStart, view: UIView(), location: CGPoint(x: 0.0, y: 1.1))

        assertEventTypeCount(type: NIDEventName.touchStart.rawValue, expectedCount: 1)
    }
}
