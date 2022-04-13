import Foundation

public struct DataStore {
    static let eventsKey = "events_pending"

    @Atomic
    static var events: [NIDEvent] = []

    static func insertEvent(screen: String, event: NIDEvent) {
        if NeuroID.isStopped() {
            return
        }

        if event.tg?["tgs"] != nil, NeuroID.excludedViewsTestIDs.contains(where: { $0 == event.tg!["tgs"]!.toString() }) {
            return
        }

        // Ensure this event is not on the exclude list
        if NeuroID.excludedViewsTestIDs.contains(where: { $0 == event.tgs || $0 == event.en }) {
            return
        }

        // Do not capture any events bound to RNScreensNavigationController as we will double count if we do
        if let eventURL = event.url, eventURL.contains("RNScreensNavigationController") {
            return
        }

        events.append(event)
    }

    static func getAllEvents() -> [NIDEvent] {
        events
    }

    static func removeSentEvents() {
        events = []
    }
}
