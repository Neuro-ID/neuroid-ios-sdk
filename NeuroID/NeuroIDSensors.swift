//
//  NeuroIDSensors.swift
//  NeuroID
//
//  Created by Jose Perez on 06/07/22.
//
import CoreMotion
import Foundation
/// Sensor manager to get data current
final class NIDSensorManager: NSObject {
    /// Instance of the class
    static let shared: NIDSensorManager = NIDSensorManager()
    /// Motion manger for all the sensor
    let manager: CMMotionManager = CMMotionManager()
    /// Motion Sensor Data
    private var sensorData: [NIDSensorType: NIDSensorData] = [:]
    override init() {
        super.init()
        manager.deviceMotionUpdateInterval = 0.1
        self.manager.startDeviceMotionUpdates(to: .main) { motion, error in
            if let accData = motion?.userAcceleration {
                let axisX: Double = accData.x
                let axisY: Double = accData.y
                let axisZ: Double = accData.z
                let data: NIDSensorData = NIDSensorData(axisX: axisX, axisY: axisY, axisZ: axisZ)
                self.sensorData[.accelerometer] = data
            }
            if let gyroData = motion?.rotationRate {
                let axisX: Double = gyroData.x
                let axisY: Double = gyroData.y
                let axisZ: Double = gyroData.z
                let data: NIDSensorData = NIDSensorData(axisX: axisX, axisY: axisY, axisZ: axisZ)
                self.sensorData[.gyro] = data
            }
        }
        update()
    }
    /// Update data from sensor every 0.2 seconds
    private func update() {
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            NIDPrintLog(self.sensorData)
            if let accData = self.manager.accelerometerData?.acceleration {
                let axisX: Double = accData.x
                let axisY: Double = accData.y
                let axisZ: Double = accData.z
                let data: NIDSensorData = NIDSensorData(axisX: axisX, axisY: axisY, axisZ: axisZ)
                self.sensorData[.accelerometer] = data
            }
            if let gyroData = self.manager.gyroData?.rotationRate {
                let axisX: Double = gyroData.x
                let axisY: Double = gyroData.y
                let axisZ: Double = gyroData.z
                let data: NIDSensorData = NIDSensorData(axisX: axisX, axisY: axisY, axisZ: axisZ)
                self.sensorData[.gyro] = data
            }
        }
    }
    /// A Boolean value that indicates whether an sensor is available on the device.
    /// - Parameter sensor: Type of sensor
    /// - Returns: A Boolean value
    func isSensorAvailable(_ sensor: NIDSensorType) -> Bool {
        switch sensor {
        case .accelerometer:
            NIDPrintLog("Is \(sensor.rawValue): \(manager.isAccelerometerAvailable)")
            return manager.isAccelerometerAvailable
        case .gyro:
            NIDPrintLog("Is \(sensor.rawValue): \(manager.isGyroAvailable)")
            return manager.isGyroAvailable
        }
    }
    /// The lastest sample of data
    /// - Parameter sensor: Type of sensor
    /// - Returns: Lastest data or empty String
    func getSensorData(sensor: NIDSensorType) -> String {
        if let data = sensorData[sensor] {
            return "D: \(sensor.rawValue)" + "axisX: \(String(describing: data.axisX)) axisY: \(String(describing: data.axisY)) axisZ: \(String(describing: data.axisZ))"
        }
        return ""
    }
}
/// Type of sensor available to map
enum NIDSensorType: String, CustomStringConvertible {
    case accelerometer = "Accelerometer"
    case gyro = "Gyroscope"
    var description: String {
        return "D: \(self.rawValue)"
    }
}
/// Struct for the data of the sensor
struct NIDSensorData: CustomStringConvertible, Codable {
    /// Data from axis X
    var axisX: Double
    ///  Data from axis Y
    var axisY: Double
    /// Data from axis Z
    var axisZ: Double
    init(axisX: Double, axisY: Double, axisZ: Double) {
        self.axisX = axisX
        self.axisY = axisY
        self.axisZ = axisZ
    }
    var description: String {
        return "axisX: \(String(describing: axisX)) axisY: \(String(describing: axisY)) axisZ: \(String(describing: axisZ))"
    }
}
