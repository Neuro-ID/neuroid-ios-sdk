//
//  NIDSend.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Alamofire
import Foundation

extension NeuroID {
    static var networkService: NIDNetworkServiceProtocol = NIDNetworkServiceImpl()

    static var collectionURL = Constants.productionURL.rawValue

    static func getCollectionEndpointURL() -> String {
        return collectionURL
    }

    static func initTimer() {
        // Send up the first payload, and then setup a repeating timer
        DispatchQueue
            .global(qos: .utility)
            .asyncAfter(deadline: .now() + Double(NeuroID.configService.configCache.eventQueueFlushInterval)) {
                self.send()
                self.initTimer()
            }
    }

    static func initCollectionTimer() {
        if let workItem = NeuroID.sendCollectionWorkItem {
            // Send up the first payload, and then setup a repeating timer
            DispatchQueue
                .global(qos: .utility)
                .asyncAfter(
                    deadline: .now() + SEND_INTERVAL,
                    execute: workItem
                )
        }
    }

    static func createCollectionWorkItem() -> DispatchWorkItem {
        let workItem = DispatchWorkItem {
            guard !(NeuroID.sendCollectionWorkItem?.isCancelled ?? false) else {
                return
            }

            if !NeuroID.isStopped() {
                self.send()
                self.initCollectionTimer()
            }
        }

        return workItem
    }

    static func initGyroAccelCollectionTimer() {
        // If gyro cadence not enabled, early return
        if !NeuroID.configService.configCache.gyroAccelCadence {
            return
        }
        if let workItem = NeuroID.sendGyroAccelCollectionWorkItem {
            // Send up the first payload, and then setup a repeating timer
            DispatchQueue
                .global(qos: .utility)
                .asyncAfter(
                    deadline: .now() + Double(NeuroID.configService.configCache.gyroAccelCadenceTime),
                    execute: workItem
                )
        }
    }

    static func createGyroAccelCollectionWorkItem() -> DispatchWorkItem {
        let workItem = DispatchWorkItem {
            guard !(NeuroID.sendGyroAccelCollectionWorkItem?.isCancelled ?? false) else {
                return
            }

            if !NeuroID.isStopped() {
                let nidEvent = NIDEvent(type: .cadenceReadingAccel)
                nidEvent.attrs = [
                    Attrs(n: "interval", v: "\(NeuroID.configService.configCache.gyroAccelCadenceTime)ms"),
                ]

                NeuroID.saveEventToLocalDataStore(nidEvent)

                self.initGyroAccelCollectionTimer()
            }
        }

        return workItem
    }

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
    static func groupAndPOST(
        forceSend: Bool = false,
        completion: @escaping () -> Void = {}
    ) {
        if NeuroID.isStopped(), !forceSend {
            completion()
            return
        }

        // get and clear event queue
        let dataStoreEvents = DataStore.getAndRemoveAllEvents()

        if dataStoreEvents.isEmpty {
            completion()
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

        post(
            events: cleanEvents,
            screen: getScreenName() ?? altScreenName,
            onSuccess: {
                logInfo(category: "APICall", content: "Sending successfully")
                NeuroID.incrementPacketNumber()
                completion()
            }, onFailure: { error in
                logError(category: "APICall", content: String(describing: error))
                let sendEventsLogEvent = NIDEvent(type: NIDEventName.log, level: "ERROR", m: "Group and POST failure: \(error)")

                if !NeuroID.isSDKStarted {
                    saveQueuedEventToLocalDataStore(sendEventsLogEvent)
                } else {
                    saveEventToLocalDataStore(sendEventsLogEvent)
                }
                completion()
            }
        )
    }

    /// Direct send to API to create session
    /// Regularly send in loop
    static func post(
        events: [NIDEvent],
        screen: String,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping
        (Error) -> Void
    ) {
        guard let url = URL(string: NeuroID.getCollectionEndpointURL()) else {
            logError(content: "NeuroID base URL found")
            return
        }

        let tabId = ParamsCreator.getTabId()
        let userID = NeuroID.getUserID()
        let registeredUserID = NeuroID.getRegisteredUserID()

        let randomString = ParamsCreator.generateID()
        let pageid = randomString.replacingOccurrences(of: "-", with: "").prefix(12)

        let neuroHTTPRequest = NeuroHTTPRequest(
            clientID: NeuroID.getClientID(),
            environment: NeuroID.getEnvironment(),
            sdkVersion: NeuroID.getSDKVersion(),
            pageTag: NeuroID.getScreenName() ?? "UNKNOWN",
            responseID: ParamsCreator.generateUniqueHexID(),
            siteID: NeuroID.siteID ?? "",
            linkedSiteId: NeuroID.linkedSiteID,
            userID: userID == "" ? nil : userID,
            registeredUserID: registeredUserID == "" ? nil : registeredUserID,
            jsonEvents: events,
            tabID: "\(tabId)",
            pageID: "\(pageid)",
            url: "ios://\(NeuroID.getScreenName() ?? "")",
            packetNumber: NeuroID.getPacketNumber()
        )

        if ProcessInfo.processInfo.environment[Constants.debugJsonKey.rawValue] == "true" {
            saveDebugJSON(events: "******************** New POST to NeuroID Collector")
//            saveDebugJSON(events: dataString)
//            saveDebugJSON(events: jsonEvents):
            saveDebugJSON(events: "******************** END")
        }

        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "site_key": NeuroID.getClientKey(),
            "authority": "receiver.neuroid.cloud",
        ]

        networkService.retryableRequest(url: url, neuroHTTPRequest: neuroHTTPRequest, headers: headers, retryCount: 0) { response in
            NIDLog.i("NeuroID Response \(response.response?.statusCode ?? 000)")
            NIDLog.d(
                tag: "Payload",
                """
                \nPayload Summary
                 ClientID: \(neuroHTTPRequest.clientId)
                 UserID: \(neuroHTTPRequest.userId ?? "")
                 RegisteredUserID: \(neuroHTTPRequest.registeredUserId ?? "")
                 LinkedSiteID: \(neuroHTTPRequest.linkedSiteId ?? "")
                 TabID: \(neuroHTTPRequest.tabId)
                 Packet Number: \(neuroHTTPRequest.packetNumber)
                 SDK Version: \(neuroHTTPRequest.sdkVersion)
                 Screen Name: \(NeuroID.getScreenName() ?? "")
                 Event Count: \(neuroHTTPRequest.jsonEvents.count)
                """
            )

            switch response.result {
            case .success:
                NIDLog.i("NeuroID post to API Successful")
                onSuccess()
            case let .failure(error):
                NIDLog.e("NeuroID FAIL to post API")
                logError(content: "Neuro-ID post Error: \(error)")
                onFailure(error)
            }
        }

        // Output post data to terminal if debug
        if ProcessInfo.processInfo.environment[Constants.debugJsonKey.rawValue] == "true" {
            do {
                let data = try JSONEncoder().encode(neuroHTTPRequest)
                let str = String(data: data, encoding: .utf8)
                NIDLog.i(str ?? "")
            } catch {}
        }
    }
}
