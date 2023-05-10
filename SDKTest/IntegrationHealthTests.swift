//
//  IntegrationHealthTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 4/24/23.
//

@testable import NeuroID
import XCTest

class IntegrationHealthTests: XCTestCase {
    // TESTING FUNCTIONS ONLY
    func generateEvents() -> [NIDEvent] {
        let textControl = UITextField()
        textControl.accessibilityIdentifier = "text 1"
        textControl.text = "test Text"

        let textControl2 = UITextField()
        textControl2.accessibilityIdentifier = "text 2"
        textControl2.text = "test Text 2"

        let events = [generateEvent(textControl), generateEvent(textControl, NIDEventName.input),
                      generateEvent(textControl, NIDEventName.textChange), generateEvent(textControl, NIDEventName.registerTarget),
                      generateEvent(textControl, NIDEventName.applicationSubmit), generateEvent(textControl, NIDEventName.createSession),
                      generateEvent(textControl, NIDEventName.blur),

                      generateEvent(textControl2), generateEvent(textControl2, NIDEventName.input),
                      generateEvent(textControl2, NIDEventName.textChange), generateEvent(textControl2, NIDEventName.registerTarget),
                      generateEvent(textControl2, NIDEventName.applicationSubmit), generateEvent(textControl2, NIDEventName.createSession),
                      generateEvent(textControl2, NIDEventName.blur)]

        return events
    }

    func generateEvent(_ target: UIView, _ eventType: NIDEventName = NIDEventName.textChange) -> NIDEvent {
        //    let textValue = target.text ?? ""
        //    let lengthValue = "S~C~~\(target.text?.count ?? 0)"

        // Text Change
        let textChangeTG = ["tgs": TargetValue.string(target.id)]
        let textChangeEvent = NIDEvent(type: eventType, tg: textChangeTG)

        return textChangeEvent
    }

    func test_generateTargetEvents() {
        let events = generateEvents()
        assert(events.count == 14)

//        writeNIDEventsToJSON(Contstants.integrationHealthFile.rawValue, items: events)
//
//        generateIntegrationHealthDeviceReport(UIDevice.current)

//        copyFolders()
//        copyFilesFromBundleToDocumentsFolderWith(fileExtension: ".html")
//        copyFolders()
//        var filePath = Bundle.main.url(forResource: "index", withExtension: "html")
//
//        print(filePath)
//        let path = Bundle.main.resourcePath
//        print("p \(path)")
//
//        if let fileURL = Bundle.main.url(forResource: "test.swift", withExtension: "swift") {
//            // we found the file in our bundle!
//            print("file url")
//        } else {
//            print("nope")
//        }
    }
}
