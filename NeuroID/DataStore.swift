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
        var newEvent = event
        let sensorManager = NIDSensorManager.shared
        NeuroID.logDebug(category: "Sensor Accel", content: sensorManager.isSensorAvailable(.accelerometer))
        NeuroID.logDebug(category: "Sensor Gyro", content: sensorManager.isSensorAvailable(.gyro))
        newEvent.gyro = sensorManager.getSensorData(sensor: .gyro)
        newEvent.accel = sensorManager.getSensorData(sensor: .accelerometer)
        
        NeuroID.logDebug(category: "saveEvent", content: newEvent.toDict())
        
        #if DEBUG
        print("Accelerometer: ", newEvent.accel)
        print("Gyroscope: ", newEvent.gyro)
        #endif

        var mutableEvent = newEvent
        
        if (NeuroID.isStopped()){
            return;
        }
        
        if (!NeuroID.getScreenName().isEmptyOrNil){
            mutableEvent.url = "ios://\(NeuroID.getScreenName() ?? "")"
        }
        // Grab the current set screen and set event URL to this
        
        if (mutableEvent.tg?["tgs"] != nil) {
            if (NeuroID.excludedViewsTestIDs.contains(where: { $0 == mutableEvent.tg!["tgs"]!.toString() })) {
                return;
            }
        }
        // Ensure this event is not on the exclude list
        if (NeuroID.excludedViewsTestIDs.contains(where: {$0 == mutableEvent.tgs || $0 == mutableEvent.en})) {
            return;
        }
                
        // Do not capture any events bound to RNScreensNavigationController as we will double count if we do
        if let eventURL = mutableEvent.url {
            if (eventURL.contains("RNScreensNavigationController")) {
                return
            }
        }
        DispatchQueue.global(qos: .utility).sync {
            DataStore.events.append(mutableEvent)
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
