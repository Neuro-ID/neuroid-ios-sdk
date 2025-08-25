//
//  MockEventStorageService.swift
//  NeuroID
//
//  Created by Kevin Sites on 8/25/25.
//

@testable import NeuroID

class MockEventStorageService: EventStorageServiceProtocol {
    var saveEventToDataStoreCount = 0
    var saveEventToLocalDataStoreCount = 0

    var mockEventStore: [NIDEvent] = .init()

    func saveEventToDataStore(_ event: NIDEvent) {
        saveEventToDataStore(event, screen: nil)
    }

    func saveEventToDataStore(_ event: NIDEvent, screen: String?) {
        saveEventToDataStoreCount += 1
        mockEventStore.append(event)
    }

    func saveEventToLocalDataStore(_ event: NIDEvent) {
        saveEventToLocalDataStore(event, screen: nil)
    }

    func saveEventToLocalDataStore(_ event: NIDEvent, screen: String?) {
        saveEventToLocalDataStoreCount += 1
        mockEventStore.append(event)
    }

    func clearMockCount() {
        saveEventToDataStoreCount = 0
        saveEventToLocalDataStoreCount = 0
        mockEventStore = .init()
    }
}
