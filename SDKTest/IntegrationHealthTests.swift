//
//  IntegrationHealthTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 4/24/23.
//

@testable import NeuroID
import XCTest

class IntegrationHealthTests: XCTestCase {
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
