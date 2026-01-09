import Foundation

protocol DataStoreServiceProtocol {
    func insertCleanedEvent(event: NIDEvent, storeType: String)
    func getAllEvents() -> [NIDEvent]
    func removeSentEvents()
    func getAndRemoveAllEvents() -> [NIDEvent]
    func getAndRemoveAllQueuedEvents() -> [NIDEvent]
    func forceClearAllEvents()

    func getAllEventCount() -> Int
    func checkLastEventType(type: String) -> Bool
}

public class DataStore: DataStoreServiceProtocol {
    let logger: LoggerProtocol

    var _events = [NIDEvent]()
    private let lock = NSLock()

    var events: [NIDEvent] {
        get { lock.withCriticalSection { _events } }
        set { lock.withCriticalSection { _events = newValue } }
    }

    var _queuedEvents = [NIDEvent]()
    var queuedEvents: [NIDEvent] {
        get { lock.withCriticalSection { _queuedEvents } }
        set { lock.withCriticalSection { _queuedEvents = newValue } }
    }

    init(logger: LoggerProtocol) {
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

    func forceClearAllEvents() {
        events = []
        queuedEvents = []
    }

    func getAllEventCount() -> Int {
        return queuedEvents.count + events.count
    }

    func checkLastEventType(type: String) -> Bool {
        return events.last?.type != type && queuedEvents.last?.type != type
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
