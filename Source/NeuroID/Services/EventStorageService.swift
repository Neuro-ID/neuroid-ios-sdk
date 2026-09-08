//
//  EventStorageService.swift
//  NeuroID
//
//  Created by Kevin Sites on 8/4/25.
//

protocol EventStorageServiceProtocol: Sendable {
    func saveEventToDataStore(_ event: NIDEvent)

    func saveEventToLocalDataStore(_ event: NIDEvent)
}

struct EventStorageService: EventStorageServiceProtocol {
    func saveEventToDataStore(_ event: NIDEvent) {
        NeuroIDCore.shared.saveEventToDataStore(event)
    }

    func saveEventToLocalDataStore(_ event: NIDEvent) {
        NeuroIDCore.shared.saveEventToLocalDataStore(event)
    }
}
