import Foundation

public enum DataStore {
    static var _events = [NIDEvent]()
    private static let lock = NSLock()
    private static let max_event_size = 2000

    static var events: [NIDEvent] {
        get { lock.withCriticalSection { _events } }
        set { lock.withCriticalSection { _events = newValue } }
    }

    static var _queuedEvents = [NIDEvent]()
    static var queuedEvents: [NIDEvent] {
        get { lock.withCriticalSection { _queuedEvents } }
        set { lock.withCriticalSection { _queuedEvents = newValue } }
    }

    static func insertEvent(screen: String, event: NIDEvent) {
        if NeuroID.isStopped() {
            return
        }

        DataStore.cleanAndStoreEvent(screen: screen, event: event, storeType: "event")
    }

    static func insertQueuedEvent(screen: String, event: NIDEvent) {
        DataStore.cleanAndStoreEvent(screen: screen, event: event, storeType: "queue")
    }

    static func cleanAndStoreEvent(screen: String, event: NIDEvent, storeType: String) {
        let mutableEvent = event

        // Do not capture any events bound to RNScreensNavigationController as we will double count if we do
        if let eventURL = mutableEvent.url {
            if eventURL.contains("RNScreensNavigationController") {
                return
            }
        }

        // Grab the current set screen and set event URL to this
        mutableEvent.url = "ios://\(NeuroID.getScreenName() ?? "")"

        if mutableEvent.tg?["\(Constants.tgsKey.rawValue)"] != nil {
            if NeuroID.excludedViewsTestIDs.contains(where: { $0 == mutableEvent.tg!["\(Constants.tgsKey.rawValue)"]!.toString() }) {
                return
            }
        }

        // Ensure this event is not on the exclude list
        if NeuroID.excludedViewsTestIDs.contains(where: { $0 == mutableEvent.tgs || $0 == mutableEvent.en }) {
            return
        }

        let sensorManager = NIDSensorManager.shared
        mutableEvent.gyro = sensorManager.getSensorData(sensor: .gyro)
        mutableEvent.accel = sensorManager.getSensorData(sensor: .accelerometer)

        NeuroID.logDebug(category: "Sensor Accel", content: sensorManager.isSensorAvailable(.accelerometer))
        NeuroID.logDebug(category: "Sensor Gyro", content: sensorManager.isSensorAvailable(.gyro))
        NeuroID.logDebug(category: "saveEvent", content: mutableEvent.toDict())

        DataStore.insertCleanedEvent(event: mutableEvent, storeType: storeType)
    }

    static func insertCleanedEvent(event: NIDEvent, storeType: String) {
    
        // If queue has more than 2000 events, send a queue full event and return
        if (DataStore.queuedEvents.count >= 2000 || DataStore.events.count >= 20000) {
            if (DataStore.events.last?.type != NIDEventName.bufferFull.rawValue) {
                var fullEvent = NIDEvent.init(type: NIDEventName.bufferFull)
                if storeType == "queue" {
                    DataStore.queuedEvents.append(fullEvent)
                } else {
                    DataStore.events.append(fullEvent)
                }
            }
            return
        }
        
        if storeType == "queue" {
            NIDLog.d("Store Queued Event: \(event.type)")
            DispatchQueue.global(qos: .utility).sync {
                DataStore.queuedEvents.append(event)
            }
        } else {
            NeuroID.captureIntegrationHealthEvent(event.copy())
            NIDPrintEvent(event)
            DispatchQueue.global(qos: .utility).sync {
                DataStore.events.append(event)
            }
        }
    }

    static func getAllEvents() -> [NIDEvent] {
        return self.events
    }

    static func removeSentEvents() {
        self.events = []
    }

    static func getAndRemoveAllEvents() -> [NIDEvent] {
        return self.lock.withCriticalSection {
            let result = self._events
            self._events = []
            return result
        }
    }

    static func getAndRemoveAllQueuedEvents() -> [NIDEvent] {
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
