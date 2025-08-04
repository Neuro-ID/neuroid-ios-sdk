//
//  EventStorageService.swift
//  NeuroID
//
//  Created by Kevin Sites on 8/4/25.
//

protocol EventStorageProtocol {
    func saveEventToDataStore(_ event: NIDEvent)
    func saveEventToDataStore(_ event: NIDEvent, screen: String?)

    func saveEventToLocalDataStore(_ event: NIDEvent)
    func saveEventToLocalDataStore(_ event: NIDEvent, screen: String?)
}

struct EventStorageService: EventStorageProtocol {
    func saveEventToDataStore(_ event: NIDEvent) {
        NeuroID.saveEventToDataStore(event)
    }

    func saveEventToDataStore(_ event: NIDEvent, screen: String? = nil) {
        NeuroID.saveEventToDataStore(event, screen: screen)
    }

    func saveEventToLocalDataStore(_ event: NIDEvent) {
        NeuroID.saveEventToLocalDataStore(event)
    }

    func saveEventToLocalDataStore(_ event: NIDEvent, screen: String? = nil) {
        NeuroID.saveEventToLocalDataStore(event, screen: screen)
    }
}
