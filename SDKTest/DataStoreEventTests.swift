import XCTest
@testable import NeuroID

final class DataStoreEventTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DataStore.events = []
        NeuroID.start()
    }

    override class func tearDown() {
        DataStore.events = []
        super.tearDown()
    }

    func test_eventIsNotInserted_whenNeuroIDIsStopped() {
        // Given: Any event
        let event = NIDEvent(customEvent: "fake-event", tg: nil, x: nil, y: nil)

        //  When: NeuroID is stopped
        NeuroID.stop()
        XCTAssertTrue(NeuroID.isStopped())
        //   And: There is an insert try
        DataStore.insertEvent(screen: name, event: event)

        //  Then: event is not inserted
        XCTAssertTrue(DataStore.events.isEmpty)
    }

    func test_eventIsNotInserted_whenEventTargetIsInTheExcludedList() {
        // Given: Any event
        let fakeTestValue = "fake-value"
        let event = NIDEvent(customEvent: "fake-event", tg: ["tgs": .string(fakeTestValue)], x: nil, y: nil)

        XCTAssertFalse(NeuroID.isStopped())

        //  When: Test value is in the excluded list
        NeuroID.excludedViewsTestIDs = [fakeTestValue]
        //   And: There is an insert try
        DataStore.insertEvent(screen: name, event: event)

        //  Then: event is not inserted
        XCTAssertTrue(DataStore.events.isEmpty)
    }

    func test_eventIsNotInserted_whenENIsInTheExcludedList() {
        // Given: Any event
        let enValue = "fake-en-value"
        let event = NIDEvent(eventName: .change, tgs: "", en: enValue, etn: "", et: "", ec: "", v: "", url: "")

        XCTAssertFalse(NeuroID.isStopped())

        //  When: EN value is in the excluded list
        NeuroID.excludedViewsTestIDs = [enValue]
        //   And: There is an insert try
        DataStore.insertEvent(screen: name, event: event)

        //  Then: event is not inserted
        XCTAssertTrue(DataStore.events.isEmpty)
    }

    func test_eventIsNotInserted_whenEventURLContainsRNScreensNavigationController() {
        // Given: Any event, with a url containing 'RNScreensNavigationController'
        let urlValue = "app://RNScreensNavigationController"
        let event = NIDEvent(eventName: .change, tgs: "", en: "", etn: "", et: "", ec: "", v: "", url: urlValue)

        XCTAssertFalse(NeuroID.isStopped())

        //  When: There is an insert try
        DataStore.insertEvent(screen: name, event: event)

        //  Then: event is not inserted
        XCTAssertTrue(DataStore.events.isEmpty)
    }

    func test_multipleInserts_and_getAllEvents() {
        let events = (1...20)
            .map { index in
                NIDEvent(customEvent: "fake-event-\(index)", tg: nil, x: nil, y: nil)
            }

        XCTAssertFalse(NeuroID.isStopped())

        for (index, event) in events.enumerated() {
            DataStore.insertEvent(screen: "screen-\(index)", event: event)
        }

        XCTAssertEqual(
            events.sorted { $0.type > $1.type },
            DataStore.getAllEvents().sorted { $0.type > $1.type }
        )
    }

    func test_removeSentEvents_clearsTheEventsList() {
        let eventsCount = 20

        let events = (1...eventsCount)
            .map { index in
                NIDEvent(customEvent: "fake-event-\(index)", tg: nil, x: nil, y: nil)
            }

        for (index, event) in events.enumerated() {
            DataStore.insertEvent(screen: "screen-\(index)", event: event)
        }

        XCTAssertEqual(eventsCount, DataStore.getAllEvents().count)

        DataStore.removeSentEvents()

        XCTAssertTrue(DataStore.getAllEvents().isEmpty)
    }

    func test_inserting_fromMultipleQueues() {
        let eventsCount = 50
        let events = (1...eventsCount)
            .map { index in
                NIDEvent(customEvent: "fake-event-\(index)", tg: nil, x: nil, y: nil)
            }

        let dispatchGroup = DispatchGroup()
        let multithreadingInsert = expectation(description: "multithreading insert")

        for (index, event) in events.enumerated() {
            dispatchGroup.enter()
            DispatchQueue.global().async {
                DataStore.insertEvent(screen: "screen-\(index)", event: event)
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            multithreadingInsert.fulfill()
        }

        wait(for: [multithreadingInsert], timeout: 1.0)
    }
}
