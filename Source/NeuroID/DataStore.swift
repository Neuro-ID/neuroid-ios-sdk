import Foundation

public class DataStore {
    let logger: NIDLog

    var _events = [NIDEvent]()
    private let lock = NSLock()
    private let max_event_size = 1999

    var events: [NIDEvent] {
        get { lock.withCriticalSection { _events } }
        set { lock.withCriticalSection { _events = newValue } }
    }

    var _queuedEvents = [NIDEvent]()
    var queuedEvents: [NIDEvent] {
        get { lock.withCriticalSection { _queuedEvents } }
        set { lock.withCriticalSection { _queuedEvents = newValue } }
    }

    init(logger: NIDLog) {
        self.logger = logger
    }

    func insertCleanedEvent(event: NIDEvent, storeType: String) {
        if storeType == "queue" {
            logger.d("Store Queued Event: \(event.type)")
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
        return events
    }

    func removeSentEvents() {
        events = []
    }

    func getAndRemoveAllEvents() -> [NIDEvent] {
        return lock.withCriticalSection {
            let result = self._events
            let queuedResults = self._queuedEvents

            self._events = []
            self._queuedEvents = []
            return result + queuedResults
        }
    }

    func getAndRemoveAllQueuedEvents() -> [NIDEvent] {
        return lock.withCriticalSection {
            let result = self._queuedEvents
            self._queuedEvents = []
            return result
        }
    }
}

func getUserDefaultKeyBool(_ key: String) -> Bool {
    return UserDefaults.standard.bool(forKey: key)
}

func getUserDefaultKeyString(_ key: String) -> String? {
    return UserDefaults.standard.string(forKey: key)
}

func getUserDefaultKeyDouble(_ key: String) -> Double {
    return UserDefaults.standard.double(forKey: key)
}

func getUserDefaultKeyDict(_ key: String) -> [String: Any]? {
    return UserDefaults.standard.dictionary(forKey: key)
}

func setUserDefaultKey(_ key: String, value: Any?) {
    UserDefaults.standard.set(value, forKey: key)
}

extension NSLocking {
    func withCriticalSection<T>(block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }
}
