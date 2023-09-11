//
//  NIDSend.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Alamofire
import Foundation

public extension NeuroID {
    internal static func initTimer() {
        // Send up the first payload, and then setup a repeating timer
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + SEND_INTERVAL) {
            self.send()
            self.initTimer()
        }
    }

    static func getCollectionEndpointURL() -> String {
        return "https://receiver.neuroid.cloud/c"
    }

    /**
     Publically exposed just for testing. This should not be any reason to call this directly.
     */
    static func send() {
        DispatchQueue.global(qos: .utility).async {
            if !NeuroID.isStopped() {
                groupAndPOST()
            }
        }
    }

    /**
     Publically exposed just for testing. This should not be any reason to call this directly.
     */
    static func groupAndPOST() {
        if NeuroID.isStopped() {
            return
        }

        // get and clear event queue
        let dataStoreEvents = DataStore.getAndRemoveAllEvents()

        if dataStoreEvents.isEmpty {
            return
        }

        // save captured health events to file
        saveIntegrationHealthEvents()

        // capture first event url as backup screen name
        let altScreenName = dataStoreEvents.first?.url ?? "unnamed_screen"

        /** Just send all the evnets */
        let cleanEvents = dataStoreEvents.map { nidevent -> NIDEvent in
            let newEvent = nidevent
            // Only send url on register target and create session.
            if nidevent.type != NIDEventName.registerTarget.rawValue, nidevent.type != "\(NIDEventName.createSession.rawValue)" {
                newEvent.url = nil
            }
            return newEvent
        }

        post(events: cleanEvents, screen: getScreenName() ?? altScreenName, onSuccess: { _ in
            logInfo(category: "APICall", content: "Sending successfully")
            // send success -> delete

        }, onFailure: { error in
            logError(category: "APICall", content: String(describing: error))
        })
    }

    static func retryableRequest(url: URL, neuroHTTPRequest: NeuroHTTPRequest, headers: HTTPHeaders, retryCount: Int, completion: @escaping (AFDataResponse<Data>) -> Void) {
        AF.request(
            url,
            method: .post,
            parameters: neuroHTTPRequest,
            encoder: JSONParameterEncoder.default,
            headers: headers
        ).responseData { response in
            completion(response)

            if response.error != nil, retryCount > 0 {
                print("NeruoID network Retrying...")
                retryableRequest(url: url, neuroHTTPRequest: neuroHTTPRequest, headers: headers, retryCount: retryCount - 1, completion: completion)
            }
        }
    }

    /// Direct send to API to create session
    /// Regularly send in loop
    fileprivate static func post(events: [NIDEvent],
                                 screen: String,
                                 onSuccess: @escaping (Any) -> Void,
                                 onFailure: @escaping
                                 (Error) -> Void)
    {
        guard let url = URL(string: NeuroID.getCollectionEndpointURL()) else {
            logError(content: "NeuroID base URL found")
            return
        }

        let tabId = ParamsCreator.getTabId()

        let randomString = ParamsCreator.genId()
        let pageid = randomString.replacingOccurrences(of: "-", with: "").prefix(12)

        let neuroHTTPRequest = NeuroHTTPRequest(
            clientId: NeuroID.getClientID(),
            environment: NeuroID.getEnvironment(),
            sdkVersion: ParamsCreator.getSDKVersion(),
            pageTag: NeuroID.getScreenName() ?? "UNKNOWN",
            responseId: ParamsCreator.generateUniqueHexId(),
            siteId: NeuroID.siteId ?? "",
            userId: NeuroID.getUserID(),
            jsonEvents: events,
            tabId: "\(tabId)",
            pageId: "\(pageid)",
            url: "ios://\(NeuroID.getScreenName() ?? "")"
        )

        if ProcessInfo.processInfo.environment[Constants.debugJsonKey.rawValue] == "true" {
            saveDebugJSON(events: "******************** New POST to NID Collector")
//            saveDebugJSON(events: dataString)
//            saveDebugJSON(events: jsonEvents):
            saveDebugJSON(events: "******************** END")
        }

        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "site_key": NeuroID.getClientKey(),
            "authority": "receiver.neuroid.cloud",
        ]

        let maxRetries = 3

        retryableRequest(url: url, neuroHTTPRequest: neuroHTTPRequest, headers: headers, retryCount: maxRetries) { response in
            NIDPrintLog("NID Response \(response.response?.statusCode ?? 000)")
            NIDPrintLog("NID Payload: \(neuroHTTPRequest)")
            switch response.result {
            case .success:
                NIDPrintLog("Neuro-ID post to API Successful")
            case let .failure(error):
                NIDPrintLog("Neuro-ID FAIL to post API")
                logError(content: "Neuro-ID post Error: \(error)")
            }
        }

        // Output post data to terminal if debug
        if ProcessInfo.processInfo.environment[Constants.debugJsonKey.rawValue] == "true" {
            do {
                let data = try JSONEncoder().encode(neuroHTTPRequest)
                let str = String(data: data, encoding: .utf8)
                NIDPrintLog(str as Any)
            } catch {}
        }
    }
}
