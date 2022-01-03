//
//  UserActivityDetection.swift
//  NeuroID
//
//  Created by Clayton Selby on 1/2/22.
//

import Foundation
import CoreML
import CoreMotion

@available(iOS 15.0, *)
class UserActivityDetection {
    struct ModelConstants {
            static let numOfFeatures = 6
            // Must be the same value you used while training
            static let predictionWindowSize = 30
            // Must be the same value you used while training
            static let sensorsUpdateFrequency = 1.0 / 10.0
            static let hiddenInLength = 200
            static let hiddenCellInLength = 200
        }
        
        // Initialize the model, layers, and prediction window
//    private let classifier = NIDAccelerometerModelV1.init(contentsOf: <#T##URL#>)
//        private let modelName:String = "ActivityClassifier"
    // Initialize the model, layers, and sensor data arrays
      var currentIndexInPredictionWindow = 0
    let accX = try? MLMultiArray(
        shape: [ModelConstants.predictionWindowSize] as [NSNumber],
        dataType: MLMultiArrayDataType.double)
    let accY = try? MLMultiArray(
        shape: [ModelConstants.predictionWindowSize] as [NSNumber],
        dataType: MLMultiArrayDataType.double)
    let accZ = try? MLMultiArray(
        shape: [ModelConstants.predictionWindowSize] as [NSNumber],
        dataType: MLMultiArrayDataType.double)
    let rotX = try? MLMultiArray(
        shape: [ModelConstants.predictionWindowSize] as [NSNumber],
        dataType: MLMultiArrayDataType.double)
    let rotY = try? MLMultiArray(
        shape: [ModelConstants.predictionWindowSize] as [NSNumber],
        dataType: MLMultiArrayDataType.double)
    let rotZ = try? MLMultiArray(
        shape: [ModelConstants.predictionWindowSize] as [NSNumber],
        dataType: MLMultiArrayDataType.double)
    var currentState = try? MLMultiArray(
        shape: [(ModelConstants.hiddenInLength +
          ModelConstants.hiddenCellInLength) as NSNumber],
        dataType: MLMultiArrayDataType.double)
    // Initialize CoreMotion Manager
      let motionManager = CMMotionManager()
    // Initialize the label that will get updated
    
    func activityPrediction() -> String? {
        // Perform prediction
        do {
        let modelURL = Bundle.main.url(forResource: "NIDAccelerometerModelV1", withExtension: "mlmodelc")
//        private let classifier = NIDAccelerometerModelV1.init(contentsOf: <#T##URL#>)
            let classifier =   try NIDAccelerometerModelV1.init(contentsOf: modelURL!)
        
          let modelPrediction = try? classifier.prediction(
            acceleration_x: accX!,
            acceleration_y: accY!,
            acceleration_z: accZ!,
            rotation_x: rotX!,
            rotation_y: rotY!,
            rotation_z: rotZ!,
            stateIn: currentState ?? MLMultiArray.init())
        // Update the state vector
          currentState = modelPrediction?.stateOut
        // Return the predicted activity
          return modelPrediction?.label
        } catch {
            print(error)
            return nil
        }
       
    }
     

        public func stopDeviceMotion() {
            guard motionManager.isDeviceMotionAvailable else {
                debugPrint("Core Motion Data Unavailable!")
                return
              }
            // Stop streaming device data
              motionManager.stopDeviceMotionUpdates()
            // Reset some parameters
              currentIndexInPredictionWindow = 0
              currentState = try? MLMultiArray(
                shape: [(ModelConstants.hiddenInLength +
                  ModelConstants.hiddenCellInLength) as NSNumber],
                dataType: MLMultiArrayDataType.double)
            
        }
        
        public func startDeviceMotion() {
            guard motionManager.isDeviceMotionAvailable else {
                debugPrint("Core Motion Data Unavailable!")
                return
            }
            motionManager.deviceMotionUpdateInterval = ModelConstants.sensorsUpdateFrequency
            motionManager.showsDeviceMovementDisplay = true
            motionManager.startDeviceMotionUpdates(to: .main) { (motionData, error) in
                guard let motionData = motionData else { return }
                // Add motion data sample to array
                self.addMotionDataSampleToArray(motionSample: motionData)
            }
        }
        
        func addMotionDataSampleToArray(motionSample: CMDeviceMotion) {
            // Using global queue for building prediction array
          DispatchQueue.global().async {
            self.rotX![self.currentIndexInPredictionWindow] = motionSample.rotationRate.x as NSNumber
            self.rotY![self.currentIndexInPredictionWindow] = motionSample.rotationRate.y as NSNumber
            self.rotZ![self.currentIndexInPredictionWindow] = motionSample.rotationRate.z as NSNumber
             self.accX![self.currentIndexInPredictionWindow] = motionSample.userAcceleration.x as NSNumber
             self.accY![self.currentIndexInPredictionWindow] = motionSample.userAcceleration.y as NSNumber
              self.accZ![self.currentIndexInPredictionWindow] = motionSample.userAcceleration.z as NSNumber
                    
               // Update prediction array index
               self.currentIndexInPredictionWindow += 1
                    
               // If data array is full - execute a prediction
               if (self.currentIndexInPredictionWindow == ModelConstants.predictionWindowSize) {
                 // Move to main thread to update the UI
                 DispatchQueue.main.async {
                   // Use the predicted activity
                   var activityText = self.activityPrediction() ?? "N/A"
                    print("Activity text \(activityText)")
                 }
                 // Start a new prediction window from scratch
                 self.currentIndexInPredictionWindow = 0
               }
             }
           }
        }
        
        
        

