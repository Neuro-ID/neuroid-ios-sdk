//
//  DataStoreEventTests.swift
//  SDKTest
//
//  Created by jose perez on 28/04/22.
//
import XCTest
@testable import NeuroID

class DataStoreEventTests: XCTestCase {
    /// Single event insert
    /// After the first insert, I verify  if the event is there, then if the event is there, verify if the event has the same tag and type
    /// If the DataStore has no event, Its mean that the event wasnt insert
    func testInsertSingleEvent() {
        let screenID = UUID().uuidString
        let nidEvent = NIDEvent(type: .radioChange, tg: ["name":TargetValue.string("Jose")], primaryViewController: UIViewController(), view: UIViewController().view)
        DataStore.insertEvent(screen: screenID, event: nidEvent)
        if let event = DataStore.getAllEvents().first {
            let values = event.type == nidEvent.type && event.tg == nidEvent.tg
            XCTAssert(values == true, "Events are not the same")
        } else {
            XCTAssert(false, "Event is not inserted")
        }
    }
    /// Test  for multiple event insert
    /// First  I  set de data, then , I verify  if the event is there, then if the event is there, verify if the event has the same tag and type and if both events are the same the test is passed
    /// If the DataStore has at least 2 events, the insertion was successful
   func testInsertMultipleEvent() {
       let screenID = UUID().uuidString
       let nidEvent = NIDEvent(type: .radioChange, tg: ["name":TargetValue.string("Jose")], primaryViewController: UIViewController(), view: UIViewController().view)
       let screenID2 = UUID().uuidString
       let nidEvent2 = NIDEvent(type: .deviceOrientation, tg: ["name":TargetValue.string("Eduardo")], primaryViewController: UIViewController(), view: UIViewController().view)
       DataStore.insertEvent(screen: screenID, event: nidEvent)
       DataStore.insertEvent(screen: screenID2, event: nidEvent2)
       if let event = DataStore.getAllEvents().first, let event2 = DataStore.getAllEvents().last {
           let values1 = event.type == nidEvent.type && event.tg == nidEvent.tg
           let values2 = event2.type == nidEvent2.type && event2.tg == nidEvent2.tg
           XCTAssert((values1  && values2 ) == true, "Events are not the same")
       } else {
           XCTAssert(false, "Some Event is not inserted")
       }
   }
    /// Test function of get all de event
    /// First  I  set de data, then with the public function getAllEvents, get the array and get the count of the events, if is there the same number of the events, the test is successful
    func testGetAllEvents() {
        let screenID = UUID().uuidString
        let nidEvent = NIDEvent(type: .radioChange, tg: ["name":TargetValue.string("Jose")], primaryViewController: UIViewController(), view: UIViewController().view)
        let screenID2 = UUID().uuidString
        let nidEvent2 = NIDEvent(type: .deviceOrientation, tg: ["name":TargetValue.string("Eduardo")], primaryViewController: UIViewController(), view: UIViewController().view)
        let screenID3 = UUID().uuidString
        let nidEvent3 = NIDEvent(type: .deviceOrientation, tg: ["name":TargetValue.string("Perez")], primaryViewController: UIViewController(), view: UIViewController().view)
        DataStore.insertEvent(screen: screenID, event: nidEvent)
        DataStore.insertEvent(screen: screenID2, event: nidEvent2)
        DataStore.insertEvent(screen: screenID3, event: nidEvent3)
        XCTAssert(DataStore.getAllEvents().count == 3, "Some events were not insert")
    }
    /// Test function RemoveSentEvents
    /// First  I  set de data, then call the removeSentEvents, to remove the events, if the events count is 0, the test is successful
    func testRemoveSentEvents() {
        let screenID = UUID().uuidString
        let nidEvent = NIDEvent(type: .radioChange, tg: ["name":TargetValue.string("Jose")], primaryViewController: UIViewController(), view: UIViewController().view)
        let screenID2 = UUID().uuidString
        let nidEvent2 = NIDEvent(type: .deviceOrientation, tg: ["name":TargetValue.string("Eduardo")], primaryViewController: UIViewController(), view: UIViewController().view)
        let screenID3 = UUID().uuidString
        let nidEvent3 = NIDEvent(type: .deviceOrientation, tg: ["name":TargetValue.string("Eduardo")], primaryViewController: UIViewController(), view: UIViewController().view)
        DataStore.insertEvent(screen: screenID, event: nidEvent)
        DataStore.insertEvent(screen: screenID2, event: nidEvent2)
        DataStore.insertEvent(screen: screenID3, event: nidEvent3)
        DataStore.removeSentEvents()
        XCTAssert(DataStore.events.count == 0, "Remove function is not working")
    }
    /// Multi- Thread Simulation on insert
    ///  The dispatchGroup simultate multiple insertion with different time as the dispatchQueue is global and asynchronous
    /// The dispatchQueue has to finish under the limit time, if it not finish, the result will be failed
    func testConcurrencyStore()  {
        let nidEvent = NIDEvent(type: .radioChange, tg: ["name":TargetValue.string("Jose")], primaryViewController: UIViewController(), view: UIViewController().view)
        let nidEvent2 = NIDEvent(type: .deviceOrientation, tg: ["name":TargetValue.string("Eduardo")], primaryViewController: UIViewController(), view: UIViewController().view)
        let dispatchGroup = DispatchGroup()
        for i in 0...100 {
            dispatchGroup.enter()
            DispatchQueue.global().async {
                DataStore.insertEvent(screen: "Device \(i)" , event: i % 2 == 0 ? nidEvent : nidEvent2)
                dispatchGroup.leave()
            }
        }
        let result = dispatchGroup.wait(timeout: DispatchTime.now() + 5)
        print(DataStore.events.count)
        XCTAssert(result == .success)
    }
}
