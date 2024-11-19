//
//  NIDAdvancedDevice.swift
//  NeuroID
//
//  Created by Kevin Sites on 10/13/23.
//

import FingerprintPro
import Foundation

public extension NeuroID {
    internal static var deviceSignalService: DeviceSignalService = NeuroIDADV()

    static func start(
        _ advancedDeviceSignals: Bool,
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        NeuroID.start { started in
            if !started {
                completion(started)
                return
            }

            checkThenCaptureAdvancedDevice(advancedDeviceSignals)
            completion(started)
        }
    }

    static func startSession(
        _ sessionID: String? = nil,
        _ advancedDeviceSignals: Bool,
        completion: @escaping (SessionStartResult) -> Void = { _ in }
    ) {
        NeuroID.startSession(sessionID) { sessionRes in
            if !sessionRes.started {
                completion(sessionRes)
                return
            }

            checkThenCaptureAdvancedDevice(advancedDeviceSignals)
            completion(sessionRes)
        }
    }

    internal static func getCachedADV() -> Bool {
        if let storedADVKey = getUserDefaultKeyDict(Constants.storageAdvancedDeviceKey.rawValue) {
            if let exp = storedADVKey["exp"] as? Double, let requestID = storedADVKey["key"] as? String {
                let currentTimeEpoch = Date().timeIntervalSince1970

                if currentTimeEpoch < exp {
                    captureADVEvent(requestID, cached: true, latency: 0)
                    return true
                }
            }
        }

        return false
    }

    internal static func getNewADV() {
        deviceSignalService.getAdvancedDeviceSignal(
            NeuroID.clientKey ?? "",
            clientID: NeuroID.clientID,
            linkedSiteID: NeuroID.linkedSiteID
        ) { request in
            switch request {
            case .success((let requestID, let duration)):

                captureADVEvent(requestID, cached: false, latency: duration)

                setUserDefaultKey(
                    Constants.storageAdvancedDeviceKey.rawValue,
                    value: ["exp": UtilFunctions.getFutureTimeStamp(24),
                            "key": requestID] as [String: Any]
                )
            case .failure(let error):
                NeuroID.saveEventToLocalDataStore(
                    NIDEvent(type: .log, level: "ERROR", m: error.localizedDescription)
                )
                NeuroID.saveEventToDataStore(
                    NIDEvent(type: .advancedDeviceRequestFailed, m: error.localizedDescription)
                )
                return
            }
        }
    }

    internal static func captureADVEvent(_ requestID: String, cached: Bool, latency: Double) {
        NeuroID.saveEventToLocalDataStore(
            NIDEvent(
                type: .advancedDevice,
                ct: NeuroID.networkMonitor?.connectionType.rawValue,
                l: latency,
                rid: requestID,
                c: cached
            )
        )
    }

    /**
     Based on the parameter passed in AND the sampling flag, this function will make a call to the ADV library or not,
     Default is to use the global settings from the NeuroID class but can be overridden (see `start`
     or `startSession` in the `NIDAdvancedDevice.swift` file.

     Marked as `@objc` because this method can be called with reflection if the ADV library is not installed.
     Because of the reflection we use an array with a boolean instead of just boolean. Log the shouldCapture flag
     in a LOG event (isAdvancedDevice setting: <true/false>.
     */
    @objc internal static func captureAdvancedDevice(
        _ shouldCapture: [Bool] = [NeuroID.isAdvancedDevice]
    ) {
        let logEvent = NIDEvent(type: .log, level: "INFO", m: "shouldCapture setting: \(shouldCapture)")
        NeuroID.saveEventToDataStore(logEvent)

        // Verify the command is called with a true value (want to capture) AND that the session
        //  is NOT being restricted/throttled prior to calling for an ADV event

        if shouldCapture.indices.contains(0),
           shouldCapture[0],
           NeuroID.samplingService.isSessionFlowSampled
        {
            // call stored value, if expired then clear and get new one, else send existing
            if !getCachedADV() {
                getNewADV()
            }
        }
    }
}

// ADV Library

struct NIDADVKeyResponse: Codable {
    let key: String
}

protocol DeviceSignalService {
    func getAdvancedDeviceSignal(_ apiKey: String, clientID: String?, linkedSiteID: String?, completion: @escaping (Result<(String, Double), Error>) -> Void)
}

class NeuroIDADV: NSObject, DeviceSignalService {
    public func getAdvancedDeviceSignal(_ apiKey: String, clientID: String?, linkedSiteID: String?, completion: @escaping (Result<(String, Double), Error>) -> Void) {
        // Retrieve Key from NID Server for Request
        NeuroIDADV.getAPIKey(apiKey, clientID: clientID, linkedSiteID: linkedSiteID) { result in
            switch result {
            case .success(let fAPiKey):
                // Retrieve ADV Data using Request Key
                NeuroIDADV.retryAPICall(apiKey: fAPiKey, maxRetries: 3, delay: 2) { result in
                    switch result {
                    case .success(let (value, duration)):
                        completion(.success((value, duration)))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    static func getAPIKey(
        _ apiKey: String,
        clientID: String? = "",
        linkedSiteID: String? = "",
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let apiURL = URL(string: "https://receiver.neuroid.cloud/a/\(apiKey)?clientId=\(clientID ?? "")&linkedSiteId=\(linkedSiteID ?? "")")!
        let task = URLSession.shared.dataTask(with: apiURL) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 403 {
                    completion(
                        .failure(
                            createError(code: 1, description: "403")
                        )
                    )
                    return
                }

                if httpResponse.statusCode == 204 {
                    completion(
                        .failure(
                            createError(code: 8, description: "204")
                        )
                    )
                    return
                }
            }

            guard let data = data else {
                completion(
                    .failure(
                        createError(code: 2, description: "NeuroID API Error: No Data Received")
                    )
                )
                return
            }

            do {
                let decoder = JSONDecoder()
                let myResponse = try decoder.decode(NIDADVKeyResponse.self, from: data)

                if let data = Data(base64Encoded: myResponse.key) {
                    if let string = String(data: data, encoding: .utf8) {
                        completion(.success(string))
                    } else {
                        completion(
                            .failure(
                                createError(code: 3, description: "NeuroID API Error: Unable to convert to string")
                            )
                        )
                    }
                } else {
                    completion(
                        .failure(
                            createError(code: 4, description: "NeuroID API Error: Error Retrieving Data")
                        )
                    )
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }

    static func getRequestID(
        _ apiKey: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        if #available(iOS 13.0, *) {
            let region: Region = .custom(domain: "https://advanced.neuro-id.com")
            let configuration = Configuration(apiKey: apiKey, region: region)
            let client = FingerprintProFactory.getInstance(configuration)
            client.getVisitorIdResponse { result in
                switch result {
                case .success(let fResponse):
                    completion(.success(fResponse.requestId))
                case .failure(let error):
                    completion(
                        .failure(
                            createError(code: 6, description: "Fingerprint Response Failure (code 6): \(error.localizedDescription)")
                        )
                    )
                }
            }
        } else {
            completion(
                .failure(
                    createError(code: 7, description: "Fingerprint Response Failure (code 7): Method Not Available")
                )
            )
        }
    }

    static func retryAPICall(
        apiKey: String,
        maxRetries: Int,
        delay: TimeInterval,
        completion: @escaping (Result<(String, TimeInterval), Error>) -> Void
    ) {
        var currentRetry = 0

        func attemptAPICall() {
            let startTime = Date()

            getRequestID(apiKey) { result in
                if case .failure(let error) = result {
                    if error.localizedDescription.contains("Method not available") {
                        completion(.failure(error))
                    } else if currentRetry < maxRetries {
                        currentRetry += 1
                        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                            attemptAPICall()
                        }
                    } else {
                        completion(.failure(error))
                    }
                } else if case .success(let value) = result {
                    let duration = Date().timeIntervalSince(startTime) * 1000
                    completion(.success((value, duration)))
                }
            }
        }

        attemptAPICall()
    }

    static func createError(code: Int, description: String) -> NSError {
        return NSError(
            domain: "NeuroIDAdvancedDevice",
            code: code,
            userInfo: [
                NSLocalizedDescriptionKey: description,
            ]
        )
    }
}
