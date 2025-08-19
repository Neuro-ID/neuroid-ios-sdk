//
//  EventStorageService.swift
//  NeuroID
//
//  Created by Kevin Sites on 8/4/25.
//

protocol EventStorageServiceProtocol {
    func saveEventToDataStore(_ event: NIDEvent)
    func saveEventToDataStore(_ event: NIDEvent, screen: String?)

    func saveEventToLocalDataStore(_ event: NIDEvent)
    func saveEventToLocalDataStore(_ event: NIDEvent, screen: String?)
}

struct EventStorageService: EventStorageServiceProtocol {
    func saveEventToDataStore(_ event: NIDEvent) {
        NeuroID.shared.saveEventToDataStore(event)
    }

    func saveEventToDataStore(_ event: NIDEvent, screen: String? = nil) {
        NeuroID.shared.saveEventToDataStore(event, screen: screen)
    }

    func saveEventToLocalDataStore(_ event: NIDEvent) {
        NeuroID.shared.saveEventToLocalDataStore(event)
    }

    func saveEventToLocalDataStore(_ event: NIDEvent, screen: String? = nil) {
        NeuroID.shared.saveEventToLocalDataStore(event, screen: screen)
    }
}
