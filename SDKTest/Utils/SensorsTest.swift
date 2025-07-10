//
//  SensorsTest.swift
//  SDKTest
//
//  Created by jose perez on 14/07/22.
//

import XCTest
import NeuroID
class SensorsTest: XCTestCase {

    let instance: NIDSensorManager = NIDSensorManager.shared
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    func testGetAccelerometerData() {
        let data = instance.getSensorData(sensor: .accelerometer)
        XCTAssertNil(data)
    }
    func testGetGyroData() {
        let data = instance.getSensorData(sensor: .gyro)
        XCTAssertNil(data)
    }
    func testSensorAvailble() {
        let accel = instance.isSensorAvailable( .accelerometer)
        let gyro = instance.isSensorAvailable( .gyro)
        XCTAssertFalse(accel)
        XCTAssertFalse(gyro)
    }
}
