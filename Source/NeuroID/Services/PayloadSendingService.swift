//
//  PayloadSendingService.swift
//  NeuroID
//
//  Created by Kevin Sites on 8/11/25.
//

import Alamofire
import Foundation

protocol PayloadSendingServiceProtocol {
    func cleanAndSendEvents(
        clientKey: String,
        screenName: String?,
        onPacketIncrement: () -> Void,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (Error) -> Void,
        eventSubset: [NIDEvent]?
    )

    func updateTestingCollectionUrl(isDev: Bool)
}

class PayloadSendingService: PayloadSendingServiceProtocol {
    static var COLLECTION_URL = Constants.productionURL.rawValue
    static let SEND_INTERVAL: Double = 5

    static func getCollectionEndpointURL() -> String {
        return self.COLLECTION_URL
    }

    static func buildStaticPayload(events: [NIDEvent], screen: String) -> NeuroHTTPRequest {
        let tabId = ParamsCreator.getTabId()
        let sessionID = NeuroID.getSessionID()
        let registeredUserID = NeuroID.getRegisteredUserID()

        let randomString = ParamsCreator.generateID()
        let pageid = randomString.replacingOccurrences(of: "-", with: "").prefix(12)

        return NeuroHTTPRequest(
            clientID: NeuroID.getClientID(),
            environment: NeuroID.getEnvironment(),
            sdkVersion: NeuroID.getSDKVersion(),
            pageTag: screen,
            responseID: ParamsCreator.generateUniqueHexID(),
            siteID: NeuroID.shared.siteID ?? "",
            linkedSiteID: NeuroID.shared.linkedSiteID,
            sessionID: sessionID == "" ? nil : sessionID,
            registeredUserID: registeredUserID == "" ? nil : registeredUserID,
            jsonEvents: events,
            tabID: "\(tabId)",
            pageID: "\(pageid)",
            url: "ios://\(NeuroID.getScreenName() ?? "")",
            packetNumber: NeuroID.shared.getPacketNumber()
        )
    }

    let logger: LoggerProtocol
    let datastore: DataStoreServiceProtocol
    let networkService: NetworkServiceProtocol

    // variable to store fn for testing, will default to buildStaticPayload until refactored
    var buildPayload: ((_: [NIDEvent], _: String) -> NeuroHTTPRequest)?

    init(
        logger: LoggerProtocol,
        datastore: DataStoreServiceProtocol,
        networkService: NetworkServiceProtocol,
        buildPayload: ((_: [NIDEvent], _: String) -> NeuroHTTPRequest)? = nil
    ) {
        self.logger = logger
        self.datastore = datastore
        self.networkService = networkService
        self.buildPayload = buildPayload
    }

    /**
     Publically exposed just for testing. This should not be any reason to call this directly.
     */
    func cleanAndSendEvents(
        clientKey: String,
        screenName: String?,
        onPacketIncrement: () -> Void = {},
        onSuccess: @escaping () -> Void = {},
        onFailure: @escaping (Error) -> Void = { _ in },
        eventSubset: [NIDEvent]? = nil
    ) {
        let dataStoreEvents = (eventSubset ?? self.datastore.getAndRemoveAllEvents())

        if dataStoreEvents.isEmpty {
            onSuccess()
            return
        }

        // capture first event url as backup screen name
        let altScreenName = dataStoreEvents.first?.url ?? "unnamed_screen"

        let cleanEvents = dataStoreEvents.map { nidevent -> NIDEvent in
            // Only send url on register target and create session events
            if nidevent.type != NIDEventName.registerTarget.rawValue,
               nidevent.type != NIDEventName.createSession.rawValue
            {
                nidevent.url = nil
            }
            return nidevent
        }

        onPacketIncrement()
        self.post(
            screen: screenName ?? altScreenName,
            clientKey: clientKey,
            events: cleanEvents,
            onSuccess: onSuccess,
            onFailure: onFailure
        )
    }

    /// Direct send to API to create session
    /// Regularly send in loop
    func post(
        screen: String,
        clientKey: String,
        events: [NIDEvent],
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        guard let url = URL(string: PayloadSendingService.getCollectionEndpointURL()) else {
            self.logger.e("NeuroID Base URL NOT found")
            return
        }

        // if stored fn use that (testing purposes) otherwise fallback to static instance
        let neuroHTTPRequest = (self.buildPayload ?? PayloadSendingService.buildStaticPayload)(events, screen)

        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "site_key": clientKey,
            "authority": "receiver.neuroid.cloud",
        ]

        self.networkService.retryableRequest(
            url: url,
            neuroHTTPRequest: neuroHTTPRequest,
            headers: headers,
            retryCount: 0
        ) { response in
            self.logger.i("NeuroID API Response \(response.response?.statusCode ?? 000)")
            self.logger.d(
                tag: "Payload",
                """
                \nPayload Summary
                 ClientID: \(neuroHTTPRequest.clientId)
                 SessionID: \(neuroHTTPRequest.userId ?? "")
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
                self.logger.i("NeuroID post to API Successful")
                onSuccess()
            case let .failure(error):
                self.logger.e("NeuroID FAIL to post API")
                onFailure(error)
            }
        }
    }

    func updateTestingCollectionUrl(isDev: Bool) {
        PayloadSendingService.COLLECTION_URL = isDev ? Constants.developmentURL.rawValue : Constants.productionURL.rawValue
    }
}
