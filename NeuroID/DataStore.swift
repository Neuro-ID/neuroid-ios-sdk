import Foundation

public struct DataStore {
    static let eventsKey = "events_pending"
    static var events = [NIDEvent]()

    static func insertEvent(screen: String, event: NIDEvent)
    {
        if (NeuroID.isStopped()){
            return;
        }
        
        if (event.tg?["tgs"] != nil) {
            if (NeuroID.excludedViewsTestIDs.contains(where: { $0 == event.tg!["tgs"]!.toString() })) {
                return;
            }
        }
        // Ensure this event is not on the exclude list
        if (NeuroID.excludedViewsTestIDs.contains(where: {$0 == event.tgs || $0 == event.en})) {
            return;
        }
                
        // Do not capture any events bound to RNScreensNavigationController as we will double count if we do
        if let eventURL = event.url {
            if (eventURL.contains("RNScreensNavigationController")) {
                return
            }
        }
        events.append(event)
    }
    
    static func getAllEvents() ->  [NIDEvent]{
        return self.events
    }
    
    static func removeSentEvents() {
        self.events = []
    }
}
