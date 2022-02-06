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
        if (NeuroID.isStopped()){
            return;
        }
        
        // Do not capture any events bound to RNScreensNavigationController as we will double count if we do
        if let eventURL = event.url {
            if (eventURL.contains("RNScreensNavigationController")) {
                return
            }
        }
        
        DispatchQueue.global(qos:.utility).async {
            if ProcessInfo.processInfo.environment["debugJSON"] == "true" {
                print("DEBUG JSON IS SET, writing to Desktop")
                do {
                    let encoder = JSONEncoder()
                    let nidJSON:Data = try encoder.encode([event])

                    let filemgr = FileManager.default
                    let path = filemgr.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("nidJSON.txt")
                    
                    if !filemgr.fileExists(atPath: (path.path)) {
                        filemgr.createFile(atPath: (path.path), contents: nidJSON, attributes: nil)
                        
                    } else {
                        let file = FileHandle(forReadingAtPath: (path.path))
                        if let fileUpdater = try? FileHandle(forUpdating: path) {
            
                            // Function which when called will cause all updates to start from end of the file
                            fileUpdater.seekToEndOfFile()

                            // Which lets the caller move editing to any position within the file by supplying an offset
                            fileUpdater.write("\n".data(using: .utf8)!)
                            fileUpdater.write(nidJSON)
                        }
                        else {
                            print("Unable to append DEBUG JSON")
                        }
                    }
                } catch{
                    print(String(describing: error))
                }
                print("INSERT EVENT: \(screen) : \(String(describing: event)))")
            }
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
            if ProcessInfo.processInfo.environment["debugJSON"] == "true" {
                print("No events..(or bad JSON event)")
            }
            DataStore.removeSentEvents()
        }
        return []
    }
    
    static func removeSentEvents() {
        UserDefaults.standard.setValue([], forKey: eventsKey)
    }
}
