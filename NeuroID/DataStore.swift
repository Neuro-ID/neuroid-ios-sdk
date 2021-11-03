import Foundation

public struct DataStore {
    static let eventsKey = "events_pending"
    
    /**
     Insert a new event record into user default local storage (append to end of current events)
       1) All new events are stored in pending events stored in events_pending
       2) Sent events are saved in events_sent
       3) events_sent queue is cleared every minute
          
     */
    static func insertEvent(screen: String, event: NIDEvent)
    {
        let encoder = JSONEncoder()
        
        // Attempt to add to existing events first, if this fails, then we don't have data to decode so set a single event
        do {
            let existingEvents = UserDefaults.standard.object(forKey: eventsKey)
            var parsedEvents = try JSONDecoder().decode([NIDEvent].self, from: existingEvents as? Data ?? Data())
            parsedEvents.append(event)
            let allEvents = try encoder.encode(parsedEvents)
            UserDefaults.standard.setValue(allEvents, forKey: eventsKey)
            return
         } catch {
            /// Swallow error
            // TODO, pattern to avoid try catch?
        }
        
        // Setting local storage to a single event
        do {
            let singleEvent = try encoder.encode([event])
            UserDefaults.standard.setValue(singleEvent, forKey: eventsKey)
        } catch {
            // If we fail here, there is something wrong with storing the event, print the error and clear the
            print(String(describing: error))
        }
    }
    
    static func getAllEvents() ->  [NIDEvent]{
        let existingEvents = UserDefaults.standard.object(forKey: eventsKey)
        
        if (existingEvents == nil){
            return []
        }
        do {
            let parsedEvents = try JSONDecoder().decode([NIDEvent].self, from: existingEvents as? Data ?? Data())
            return parsedEvents
        } catch {
            print(String(describing: error))
            print("Problem getting all events, clearing event cache")
            DataStore.removeSentEvents()
            
        }
        return []
    }
    
    static func removeSentEvents() {
        UserDefaults.standard.setValue([], forKey: eventsKey)

    }
}
