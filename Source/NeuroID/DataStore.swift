import Foundation

public class DataStore {
    var _events = [NIDEvent]()
    private  let lock = NSLock()
    private  let max_event_size = 1999

     var events: [NIDEvent] {
        get { lock.withCriticalSection { _events } }
        set { lock.withCriticalSection { _events = newValue } }
    }

     var _queuedEvents = [NIDEvent]()
     var queuedEvents: [NIDEvent] {
        get { lock.withCriticalSection { _queuedEvents } }
        set { lock.withCriticalSection { _queuedEvents = newValue } }
    }     

     func insertCleanedEvent(event: NIDEvent, storeType: String) {
        if storeType == "queue" {
            NIDLog.d("Store Queued Event: \(event.type)")
            DispatchQueue.global(qos: .utility).sync {
                queuedEvents.append(event)
            }
        } else {
            NIDPrintEvent(event)
            DispatchQueue.global(qos: .utility).sync {
                events.append(event)
            }
        }
    }

     func getAllEvents() -> [NIDEvent] {
        return self.events
    }

     func removeSentEvents() {
        self.events = []
    }

     func getAndRemoveAllEvents() -> [NIDEvent] {
        return self.lock.withCriticalSection {
            let result = self._events
            let queuedResults = self._queuedEvents

            self._events = []
            self._queuedEvents = []
            return result + queuedResults
        }
    }

     func getAndRemoveAllQueuedEvents() -> [NIDEvent] {
        return self.lock.withCriticalSection {
            let result = self._queuedEvents
            self._queuedEvents = []
            return result
        }
    }
}

internal func getUserDefaultKeyBool(_ key: String) -> Bool {
    return UserDefaults.standard.bool(forKey: key)
}

internal func getUserDefaultKeyString(_ key: String) -> String? {
    return UserDefaults.standard.string(forKey: key)
}

internal func getUserDefaultKeyDouble(_ key: String) -> Double {
    return UserDefaults.standard.double(forKey: key)
}

internal func getUserDefaultKeyDict(_ key: String) -> [String: Any]? {
    return UserDefaults.standard.dictionary(forKey: key)
}

internal func setUserDefaultKey(_ key: String, value: Any?) {
    UserDefaults.standard.set(value, forKey: key)
}

extension NSLocking {
    func withCriticalSection<T>(block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }
}
