//
//  NeuroIDSensors.swift
//  NeuroID
//
//  Created by Jose Perez on 06/07/22.
//
import CoreMotion
import Foundation
/// Sensor manager to get data current
public final class NIDSensorManager: NSObject {
    /// Instance of the class
    public static let shared: NIDSensorManager = .init()
    /// Motion manger for all the sensor
    private let manager: CMMotionManager?
    /// Motion Sensor Data
    private var sensorData: [NIDSensorType: NIDSensorData] = [:]
    /// Dispatch
    private let dispatchQueue = DispatchQueue(label: "com.neuroid.sensor", attributes: .concurrent)
    override init() {
        self.manager = CMMotionManager()
        super.init()
        manager?.gyroUpdateInterval = 0.1
        manager?.accelerometerUpdateInterval = 0.1
        manager?.startAccelerometerUpdates()
        manager?.startGyroUpdates()
        update()
    }

    /// Update data from sensor every 0.2 seconds
    private func update() {
        if let accData = manager?.accelerometerData?.acceleration {
            let axisX: Double = accData.x
            let axisY: Double = accData.y
            let axisZ: Double = accData.z
            let data = NIDSensorData(axisX: axisX, axisY: axisY, axisZ: axisZ)
            dispatchQueue.async(flags: .barrier) {
                self.sensorData[.accelerometer] = data
            }
        } else {
            dispatchQueue.async(flags: .barrier) {
                self.sensorData[.accelerometer] = nil
            }
        }
        if let gyroData = manager?.gyroData?.rotationRate {
            let axisX: Double = gyroData.x
            let axisY: Double = gyroData.y
            let axisZ: Double = gyroData.z
            let data = NIDSensorData(axisX: axisX, axisY: axisY, axisZ: axisZ)
            dispatchQueue.async(flags: .barrier) {
                self.sensorData[.gyro] = data
            }
        } else {
            dispatchQueue.async(flags: .barrier) {
                self.sensorData[.gyro] = nil
            }
        }
    }

    /// A Boolean value that indicates whether an sensor is available on the device.
    /// - Parameter sensor: Type of sensor
    /// - Returns: A Boolean value
    public func isSensorAvailable(_ sensor: NIDSensorType) -> Bool {
        guard let manager = manager else {
            return false
        }
        switch sensor {
        case .accelerometer:
            NeuroID.logDebug(content: "Is \(sensor.rawValue): \(manager.isAccelerometerAvailable)")
            return manager.isAccelerometerAvailable
        case .gyro:
            NeuroID.logDebug(content: "Is \(sensor.rawValue): \(manager.isGyroAvailable)")
            return manager.isGyroAvailable
        }
    }

    /// The lastest sample of data
    /// - Parameter sensor: Type of sensor
    /// - Returns: Lastest data or nil
    public func getSensorData(sensor: NIDSensorType) -> NIDSensorData? {
        update()
        var result: NIDSensorData?
        dispatchQueue.sync {
            if let data = sensorData[sensor] {
                result = data
            }
        }
        return result
    }
}

/// Type of sensor available to map
public enum NIDSensorType: String, CustomStringConvertible {
    case accelerometer = "Accelerometer"
    case gyro = "Gyroscope"
    public var description: String {
        return "D: \(rawValue)"
    }
}

/// Struct for the data of the sensor
public struct NIDSensorData: CustomStringConvertible, Codable {
    /// Data from axis X
    var axisX: Double
    ///  Data from axis Y
    var axisY: Double
    /// Data from axis Z
    var axisZ: Double
    enum CodingKeys: String, CodingKey {
        case axisX = "x"
        case axisY = "y"
        case axisZ = "z"
    }

    init(axisX: Double, axisY: Double, axisZ: Double) {
        self.axisX = axisX
        self.axisY = axisY
        self.axisZ = axisZ
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.axisX = try container.decode(Double.self, forKey: .axisX)
        self.axisY = try container.decode(Double.self, forKey: .axisY)
        self.axisZ = try container.decode(Double.self, forKey: .axisZ)
    }

    public var description: String {
        return "axisX: \(String(describing: axisX)) axisY: \(String(describing: axisY)) axisZ: \(String(describing: axisZ))"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(axisX, forKey: .axisX)
        try container.encode(axisY, forKey: .axisY)
        try container.encode(axisZ, forKey: .axisZ)
    }
}
