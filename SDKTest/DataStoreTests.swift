//
//  DataStoreTests.swift
//  NeuroID
//
//  Created by Clayton Selby on 10/19/21.
//

@testable import NeuroID
import XCTest

class DataStoreTests: XCTestCase {
    let eventsKey = "events_pending"

    func clearOutDataStore() {
        DataStore.removeSentEvents()
    }

    override func setUpWithError() throws {
        UserDefaults.standard.setValue(nil, forKey: "events_ending")
        clearOutDataStore()
        NeuroID.stop()
        NeuroID.start()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEncodeAndDecode() throws {
        let nid1 = NIDEvent(type: .radioChange, tg: ["name": TargetValue.string("clay")], view: UIView())

        let encoder = JSONEncoder()

        do {
            let jsonData = try encoder.encode([nid1])
            UserDefaults.standard.setValue(jsonData, forKey: eventsKey)
            let existingEvents = UserDefaults.standard.object(forKey: eventsKey)
            var parsedEvents = try JSONDecoder().decode([NIDEvent].self, from: existingEvents as! Data)
            let nid2 = NIDEvent(type: .radioChange, tg: ["name": TargetValue.string("clay")], view: UIView())
            parsedEvents.append(nid2)
            print(parsedEvents)
        } catch {
            print(String(describing: error))
        }
    }

    func testInsertDataStore() throws {
        // Reset the data store
        UserDefaults.standard.setValue(nil, forKey: eventsKey)
        let nid1 = NIDEvent(type: .radioChange, tg: ["name": TargetValue.string("clayton")], primaryViewController: LoanViewControllerPersonalDetails(), view: LoanViewControllerPersonalDetails().view)
        DataStore.insertEvent(screen: "screen1", event: nid1)
        let nid2 = NIDEvent(type: .radioChange, tg: ["name": TargetValue.string("bob")], primaryViewController: UIViewController(), view: UIView())
        DataStore.insertEvent(screen: "screen2", event: nid2)
        do {
            let jsonData = try JSONEncoder().encode(DataStore.getAllEvents())
            UserDefaults.standard.setValue(jsonData, forKey: eventsKey)
            let newEvents = UserDefaults.standard.object(forKey: eventsKey)
            let parsedEvents = try JSONDecoder().decode([NIDEvent].self, from: newEvents as! Data)
            // Test Grouping
            let groupedEvents = Dictionary(grouping: parsedEvents, by: { (element: NIDEvent) in
                element.url
            })
            print("Events:", parsedEvents)
            print("Grouped Events", groupedEvents)

            let radioChangeEvents = parsedEvents.filter { $0.type == "RADIO_CHANGE" }

            XCTAssert(radioChangeEvents.count == 2)
            assert(parsedEvents.count == 4) // include CREATE_SESSION && MOBILE_METADATA event
        } catch {
            print(String(describing: error))
        }
    }
}
