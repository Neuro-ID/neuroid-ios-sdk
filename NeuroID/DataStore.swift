import Foundation

public struct DataStore {
    static let eventsKey = "events_pending"
    static var _events = [NIDEvent]()
    private static let lock = NSLock()
    
    static var events: Array<NIDEvent> {
        get { lock.withCriticalSection { _events } }
        set { lock.withCriticalSection { _events = newValue } }
    }

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
        DispatchQueue.global(qos: .utility).sync {
            DataStore.events.append(event)
        }
    }
    
    static func getAllEvents() ->  [NIDEvent]{
        return self.events
    }
    
    static func removeSentEvents() {
        self.events = []
    }
}

extension NSLocking {
    func withCriticalSection<T>(block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }
}
