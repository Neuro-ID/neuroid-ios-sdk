import Foundation

public enum DataStore {
    static let eventsKey = "events_pending"
    static var _events = [NIDEvent]()
    private static let lock = NSLock()
    
    static var events: [NIDEvent] {
        get { lock.withCriticalSection { _events } }
        set { lock.withCriticalSection { _events = newValue } }
    }

    static func insertEvent(screen: String, event: NIDEvent) {
        let sensorManager = NIDSensorManager.shared
        NeuroID.logDebug(category: "Sensor Accel", content: sensorManager.isSensorAvailable(.accelerometer))
        NeuroID.logDebug(category: "Sensor Gyro", content: sensorManager.isSensorAvailable(.gyro))
        event.gyro = sensorManager.getSensorData(sensor: .gyro)
        event.accel = sensorManager.getSensorData(sensor: .accelerometer)
        
        NeuroID.logDebug(category: "saveEvent", content: event.toDict())

        let mutableEvent = event
        
        if NeuroID.isStopped() {
            return
        }
        
        mutableEvent.url = "ios://\(NeuroID.getScreenName() ?? "")"
        // Grab the current set screen and set event URL to this
        
        if mutableEvent.tg?["\(Constants.tgsKey.rawValue)"] != nil {
            if NeuroID.excludedViewsTestIDs.contains(where: { $0 == mutableEvent.tg!["\(Constants.tgsKey.rawValue)"]!.toString() }) {
                return
            }
        }
        // Ensure this event is not on the exclude list
        if NeuroID.excludedViewsTestIDs.contains(where: { $0 == mutableEvent.tgs || $0 == mutableEvent.en }) {
            return
        }
                
        // Do not capture any events bound to RNScreensNavigationController as we will double count if we do
        if let eventURL = mutableEvent.url {
            if eventURL.contains("RNScreensNavigationController") {
                return
            }
        }
        
        NeuroID.captureIntegrationHealthEvent(mutableEvent.copy())
        
        NIDPrintEvent(mutableEvent)
 
        DispatchQueue.global(qos: .utility).sync {
            DataStore.events.append(mutableEvent)
        }
    }
    
    static func getAllEvents() -> [NIDEvent] {
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
