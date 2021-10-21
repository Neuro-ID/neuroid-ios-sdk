//
//  DataStoreTests.swift
//  NeuroID
//
//  Created by Clayton Selby on 10/19/21.
//

import XCTest
@testable import NeuroID
class DataStoreTests: XCTestCase {

    override func setUpWithError() throws {
        UserDefaults.standard.setValue(nil, forKey: "events_ending")
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInsert() throws {
        
        var nid1 = NIDEvent.init(customEvent: "one", tg: ["":""], view: UIView())
//        var nid2 = NIDEvent.init(customEvent: "twooo", tg: ["":""], view: UIView())
//        var nid3 = NIDEvent.init(customEvent: "", tg: ["":""], view: UIView())
//
        let insertValue = [nid1.toDict()].toJSONString()
        UserDefaults.standard.setValue(insertValue, forKey: eventsKey)
//
        DataStore.insertEvent(screen: "another", event: nid1)
//        DataStore.insertEvent(screen: "test", event: nid2)
//        DataStore.insertEvent(screen: "test", event: nid3)
//        
//        
//        var sid = UserDefaults.standard.string(forKey: "events_pending")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
