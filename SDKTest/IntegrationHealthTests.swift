//
//  IntegrationHealthTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 4/24/23.
//

@testable import NeuroID
import XCTest

class IntegrationHealthTests: XCTestCase {
    
    var integrationHealthService: IntegrationHealthService = IntegrationHealthService()


    override func setUp() {
        
        integrationHealthService = IntegrationHealthService()
        
    }

    override func tearDown() {
      
    }

    func allowIH() {
        integrationHealthService.setVerifyIntegrationHealth(true)
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
        integrationHealthService.setVerifyIntegrationHealth(true)
        integrationHealthService.shouldDebugIntegrationHealth {
            assert(true)
        }
        

        // set NID verify Health to false
        integrationHealthService.setVerifyIntegrationHealth(false)
        integrationHealthService.shouldDebugIntegrationHealth {
            XCTFail("Ran when VIH was FALSE")
        }
    }

    func test_startIntegrationHealthCheck() {
        allowIH()
        integrationHealthService.debugIntegrationHealthEvents = [generateTestEvent()]

        integrationHealthService.startIntegrationHealthCheck()

        assert(integrationHealthService.debugIntegrationHealthEvents.count == 0)
    }

    func test_captureIntegrationHealthEvent() {
        allowIH()
        let event = generateTestEvent()

        integrationHealthService.captureIntegrationHealthEvent(event)
        assert(integrationHealthService.debugIntegrationHealthEvents.count == 1)
    }

    func test_getIntegrationHealthEvents() {
        allowIH()

        let events = integrationHealthService.getIntegrationHealthEvents()
        assert(events.count == 0)

        integrationHealthService.debugIntegrationHealthEvents = [generateTestEvent()]

        let events2 = integrationHealthService.getIntegrationHealthEvents()
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
        assert(integrationHealthService.verifyIntegrationHealth == false)

        integrationHealthService.setVerifyIntegrationHealth(true)
        assert(integrationHealthService.verifyIntegrationHealth == true)
    }
}
