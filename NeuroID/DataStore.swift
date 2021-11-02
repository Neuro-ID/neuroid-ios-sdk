import Foundation

public struct DataStore {
//    static var shared = DataStore()
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
        
        do {
            let existingEvents = UserDefaults.standard.object(forKey: eventsKey)
            if (existingEvents != nil){
                var parsedEvents = try JSONDecoder().decode([NIDEvent].self, from: existingEvents as? Data ?? Data())
                parsedEvents.append(event)
                let allEvents = try encoder.encode(parsedEvents)
                UserDefaults.standard.setValue(allEvents, forKey: eventsKey)
            }
            else {
                let singleEvent = try encoder.encode([event])
                UserDefaults.standard.setValue(singleEvent, forKey: eventsKey)
            }
         } catch {
            print(String(describing: error))
        }
    }
    
    static func getAllEvents() ->  [NIDEvent]{
        let existingEvents = UserDefaults.standard.object(forKey: eventsKey)
        
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
