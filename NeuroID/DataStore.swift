import Foundation

public struct DataStore {
    static let eventsKey = "events_pending"
    static var events = [NIDEvent]()

    static func insertEvent(screen: String, event: NIDEvent)
    {
        if (NeuroID.isStopped()){
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
