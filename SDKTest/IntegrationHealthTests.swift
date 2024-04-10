//
//  IntegrationHealthTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 4/24/23.
//

@testable import NeuroID
import XCTest

class IntegrationHealthTests: XCTestCase {
    let clientKey = "key_live_vtotrandom_form_mobilesandbox"

    func clearOutDataStore() {
        DataStore.removeSentEvents()
    }

    override func setUpWithError() throws {
        _ = NeuroID.configure(clientKey: clientKey)
    }

    override func setUp() {
        let _ = NeuroID.start()
        NeuroID.debugIntegrationHealthEvents = []
        NeuroID.setVerifyIntegrationHealth(false)
    }

    override func tearDown() {
        _ = NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    func allowIH() {
        NeuroID.setVerifyIntegrationHealth(true)
    }

    func generateTestEvent(_ target: UIView = UITextField(), _ eventType: NIDEventName = NIDEventName.textChange) -> NIDEvent {
        // Text Change
        let textChangeTG = ["\(Constants.tgsKey.rawValue)": TargetValue.string(target.id)]
        let textChangeEvent = NIDEvent(type: eventType, tg: textChangeTG)

        return textChangeEvent
    }

    func test_formatDate() {
        let rawValue = "1992 05 04 11 00 00"
        let expectedDotValue = "1992-05-04 11:00:00"
        let expectedDashValue = "1992-05-04 11-00-00"

        let dateFormatStyle = "yyyy MM dd"
        let dateFormatter = DateFormatter()

        dateFormatter.timeZone = NSTimeZone.default
        dateFormatter.dateFormat = "\(dateFormatStyle) hh mm ss"

        let rawDate = dateFormatter.date(from: rawValue)!

        let dotValue = formatDate(date: rawDate)
        assert(dotValue == expectedDotValue)

        let dashValue = formatDate(date: rawDate, dashSeparator: true)
        assert(dashValue == expectedDashValue)
    }

//    TO-DO
//    func test_generateIntegrationHealthDeviceReport() {
//    }
//
//    func test_generateIntegrationHealthReport() {
//    }
//
//    func test_saveIntegrationHealthResources() {
//    }

    func test_shouldDebugIntegrationHealth() {
        NeuroID.setVerifyIntegrationHealth(true)
        NeuroID.shouldDebugIntegrationHealth {
            assert(true)
        }

        // set NID verify Health to false
        NeuroID.setVerifyIntegrationHealth(false)
        NeuroID.shouldDebugIntegrationHealth {
            XCTFail("Ran when VIH was FALSE")
        }
    }

    func test_startIntegrationHealthCheck() {
        allowIH()
        NeuroID.debugIntegrationHealthEvents = [generateTestEvent()]

        NeuroID.startIntegrationHealthCheck()

        assert(NeuroID.debugIntegrationHealthEvents.count == 0)
    }

    func test_captureIntegrationHealthEvent() {
        allowIH()
        let event = generateTestEvent()

        NeuroID.captureIntegrationHealthEvent(event)
        assert(NeuroID.debugIntegrationHealthEvents.count == 1)
    }

    func test_getIntegrationHealthEvents() {
        allowIH()

        let events = NeuroID.getIntegrationHealthEvents()
        assert(events.count == 0)

        NeuroID.debugIntegrationHealthEvents = [generateTestEvent()]

        let events2 = NeuroID.getIntegrationHealthEvents()
        assert(events2.count == 1)
    }

//    TO-DO
//    func test_saveIntegrationHealthEvents() {
//    }
//
//    func test_generateNIDIntegrationHealthReport() {
//    }
//
//    func test_printIntegrationHealthInstruction() {
//    }
//
    func test_setVerifyIntegrationHealth() {
        assert(NeuroID.verifyIntegrationHealth == false)

        NeuroID.setVerifyIntegrationHealth(true)
        assert(NeuroID.verifyIntegrationHealth == true)
    }
}
