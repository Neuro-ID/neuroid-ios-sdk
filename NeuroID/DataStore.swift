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
        let eventDict = [event.toDict()].toJSONString()
        let existingEvents = UserDefaults.standard.object(forKey: eventsKey)
        var eventInsert = [String: [[String:Any]]]()

        let parsedExistingEvents: [NIDEvent] = try! JSONDecoder().decode([NIDEvent].self, from: existingEvents as! Data)

        // If we have this screen in local cache add events to it
//        if (existingEvents != nil){
//            eventInsert = existingEvents as! [String : [[String:Any]]]
//            (eventInsert[screen] != nil) ? eventInsert[screen]?.append(eventDict) : (eventInsert[screen] = [eventDict]);
//        }
//        else {
//            eventInsert[screen] = [eventDict]
//        }
//        UserDefaults.standard.setValue(eventInsert, forKey: eventsKey)
    }
    
    static func getAllEvents() ->  [String:[String:Any]]{
        let existingEvents = UserDefaults.standard.object(forKey: eventsKey)
        var returnedEvents = [String:[String:Any]] ()
        if (existingEvents != nil){
            returnedEvents = existingEvents as! [String : [String:Any]]
        }
        return returnedEvents
    }
    
    static func removeSentEvents() {
        UserDefaults.standard.setValue([], forKey: eventsKey)

    }
}
