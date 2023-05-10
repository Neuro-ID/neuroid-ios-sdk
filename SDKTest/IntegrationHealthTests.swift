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
        NeuroID.configure(clientKey: clientKey)
        NeuroID.setEnvironmentProduction(false)
    }

    override func setUp() {
        NeuroID.start()
        NeuroID.debugIntegrationHealthEvents = []
        NeuroID.setEnvironmentProduction(true)
        NeuroID.setVerifyIntegrationHealth(false)
    }

    override func tearDown() {
        NeuroID.stop()

        // Clear out the DataStore Events after each test
        clearOutDataStore()
    }

    func allowIH() {
        NeuroID.setVerifyIntegrationHealth(true)
        NeuroID.setEnvironmentProduction(false)
    }

//    func getFileMngAndDirectory() -> (FileManager, URL) {
//        let fileManager = FileManager.default
//        let documentsDirectory = tempDirectoryURL!
//
//        return (fileManager, documentsDirectory)
//    }
//
//    func verifyFileExists(_ fileName: String) -> Bool {
//        let (fileManager, documentsDirectory) = getFileMngAndDirectory()
//        let fileURL = documentsDirectory.appendingPathComponent(fileName)
//
//        if fileManager.fileExists(atPath: fileURL.path) {
//            print("File exists")
//            return true
//        } else {
//            print("File does not exist")
//            return false
//        }
//    }
//
//    func removeFile(_ fileName: String) {
//        let (fileManager, documentsDirectory) = getFileMngAndDirectory()
//        let fileURL = documentsDirectory.appendingPathComponent(fileName)
//
//        do {
//            try fileManager.removeItem(at: fileURL)
//            print("File deleted successfully")
//        } catch let error as NSError {
//            print("Error deleting file: \(error.localizedDescription)")
//        }
//    }
//
//    func removeDir(directory: String) {
//        let (fileManager, documentsDirectory) = getFileMngAndDirectory()
//        let directoryURL = documentsDirectory.appendingPathComponent(directory)
//
//        if fileManager.fileExists(atPath: directoryURL.path) {
//            do {
//                try fileManager.removeItem(at: directoryURL)
//                print("Directory deleted successfully")
//            } catch let error as NSError {
//                print("Error deleting directory: \(error.localizedDescription)")
//            }
//        }
//    }

//    func generateTestEvents() -> [NIDEvent] {
//        let textControl = UITextField()
//        textControl.accessibilityIdentifier = "text 1"
//        textControl.text = "test Text"
//
//        let textControl2 = UITextField()
//        textControl2.accessibilityIdentifier = "text 2"
//        textControl2.text = "test Text 2"
//
//        let events = [generateEvent(textControl), generateEvent(textControl, NIDEventName.input),
//                      generateEvent(textControl, NIDEventName.textChange), generateEvent(textControl, NIDEventName.registerTarget),
//                      generateEvent(textControl, NIDEventName.applicationSubmit), generateEvent(textControl, NIDEventName.createSession),
//                      generateEvent(textControl, NIDEventName.blur),
//
//                      generateEvent(textControl2), generateEvent(textControl2, NIDEventName.input),
//                      generateEvent(textControl2, NIDEventName.textChange), generateEvent(textControl2, NIDEventName.registerTarget),
//                      generateEvent(textControl2, NIDEventName.applicationSubmit), generateEvent(textControl2, NIDEventName.createSession),
//                      generateEvent(textControl2, NIDEventName.blur)]
//
//        return events
//    }
//
    func generateTestEvent(_ target: UIView = UITextField(), _ eventType: NIDEventName = NIDEventName.textChange) -> NIDEvent {
        //    let textValue = target.text ?? ""
        //    let lengthValue = "S~C~~\(target.text?.count ?? 0)"

        // Text Change
        let textChangeTG = ["tgs": TargetValue.string(target.id)]
        let textChangeEvent = NIDEvent(type: eventType, tg: textChangeTG)

        return textChangeEvent
    }

//    func test_generateTargetEvents() {
//        let events = generateEvents()
//        assert(events.count == 14)
//    }

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

//    func test_generateIntegrationHealthDeviceReport() {
//        print("TEMP: \(tempDirectoryURL)")
//        let fileName = "\(Contstants.integrationFilePath.rawValue)/\(Contstants.integrationDeviceInfoFile.rawValue)"
//        // remove pre-test
//        removeFile(fileName)
//
//        generateIntegrationHealthDeviceReport(UIDevice())
//
//        let exists = verifyFileExists(fileName)
//
//        assert(exists)
//    }
//
//    func test_generateIntegrationHealthReport() {
//        let events = generateEvents()
//        assert(events.count == 14)
//    }
//
//    func test_saveIntegrationHealthResources() {
//        let events = generateEvents()
//        assert(events.count == 14)
//    }

    func test_shouldDebugIntegrationHealth() {
        // set NID to prod so should not run
        NeuroID.setVerifyIntegrationHealth(true)
        NeuroID.setEnvironmentProduction(true)
        NeuroID.shouldDebugIntegrationHealth {
            XCTFail("Ran when ENV was PROD")
        }

        // set NID verify Health to false
        NeuroID.setVerifyIntegrationHealth(false)
        NeuroID.setEnvironmentProduction(false)
        NeuroID.shouldDebugIntegrationHealth {
            XCTFail("Ran when VIH was FALSE")
        }

        // set NID verify Health to false & env to PROD
        NeuroID.setVerifyIntegrationHealth(false)
        NeuroID.setEnvironmentProduction(true)
        NeuroID.shouldDebugIntegrationHealth {
            XCTFail("Ran when VIH was FALSE && ENV was PROD")
        }

        // set NID verify Health to true & env to TEST
        NeuroID.setVerifyIntegrationHealth(true)
        NeuroID.setEnvironmentProduction(false)
        NeuroID.shouldDebugIntegrationHealth {
            assert(true)
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

//
//    func test_saveIntegrationHealthEvents() {
//        let events = generateEvents()
//        assert(events.count == 14)
//    }
//
//    func test_generateNIDIntegrationHealthReport() {
//        let events = generateEvents()
//        assert(events.count == 14)
//    }
//
//    func test_printIntegrationHealthInstruction() {
//        let events = generateEvents()
//        assert(events.count == 14)
//    }
//
    func test_setVerifyIntegrationHealth() {
        assert(NeuroID.verifyIntegrationHealth == false)

        NeuroID.setVerifyIntegrationHealth(true)
        assert(NeuroID.verifyIntegrationHealth == true)
    }
}
