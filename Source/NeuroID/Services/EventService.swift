//
//  EventService.swift
//  NeuroID
//

protocol EventServiceProtocol {
    func saveEventToDataStore(_ event: NIDEvent)

    func saveEventToLocalDataStore(_ event: NIDEvent)
}

struct EventService: EventServiceProtocol {
    func saveEventToDataStore(_ event: NIDEvent) {
        NeuroIDCore.shared.saveEventToDataStore(event)
    }

    func saveEventToLocalDataStore(_ event: NIDEvent) {
        NeuroIDCore.shared.saveEventToLocalDataStore(event)
    }
}
