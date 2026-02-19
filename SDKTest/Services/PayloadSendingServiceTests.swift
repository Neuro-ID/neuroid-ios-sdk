//
//  PayloadSendingServiceTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 8/11/25.
//

import Foundation
@testable import NeuroID
import XCTest

class PayloadSendingServiceTests: BaseTestClass {
    var mockNetworkService = MockNetworkService()
    var payloadSendingService = PayloadSendingService(
        datastore: DataStore(),
        networkService: MockNetworkService(),
        buildPayload: { events, screenName in
            NeuroHTTPRequest(
                clientID: "",
                environment: "",
                sdkVersion: "",
                pageTag: "",
                responseID: "",
                siteID: "",
                linkedSiteID: "",
                sessionID: "",
                registeredUserID: "",
                jsonEvents: events,
                tabID: "",
                pageID: screenName,
                url: "",
                packetNumber: 0
            )
        }
    )

    override func setUp() {
        clearOutDataStore()
        NeuroIDCore._isTesting = true
        mockNetworkService = MockNetworkService()
        payloadSendingService = PayloadSendingService(
            datastore: dataStore,
            networkService: mockNetworkService,
            buildPayload: { events, screenName in
                NeuroHTTPRequest(
                    clientID: "",
                    environment: "",
                    sdkVersion: "",
                    pageTag: "",
                    responseID: "",
                    siteID: "",
                    linkedSiteID: "",
                    sessionID: "",
                    registeredUserID: "",
                    jsonEvents: events,
                    tabID: "",
                    pageID: screenName,
                    url: "",
                    packetNumber: 0
                )
            }
        )

        NeuroIDCore.shared.payloadSendingService = payloadSendingService
    }

    override func tearDown() {
        clearOutDataStore()
        NeuroIDCore._isTesting = false
        mockNetworkService.resetMockCounts()
    }

    func test_cleanAndSendEvents_custom_events_empty() {
        var isSuccess = false
        var packetIncremented = false

        payloadSendingService.cleanAndSendEvents(
            clientKey: clientKey,
            screenName: "test",
            onPacketIncrement: {
                packetIncremented.toggle()
            },
            onSuccess: {
                isSuccess.toggle()
            },
            onFailure: { _ in },
            eventSubset: []
        )

        // should not increment because event count is empty and exits early
        assert(!packetIncremented)
        assert(isSuccess) // triggers on early exit
    }

    func test_cleanAndSendEvents_datastore_events_empty() {
        var isSuccess = false
        var packetIncremented = false

        payloadSendingService.cleanAndSendEvents(
            clientKey: clientKey,
            screenName: "test",
            onPacketIncrement: {
                packetIncremented.toggle()
            },
            onSuccess: {
                isSuccess.toggle()
            },
            onFailure: { _ in },
            eventSubset: nil
        )

        // should not increment because datastore event count is empty and exits early
        assert(!packetIncremented)
        assert(isSuccess) // triggers on early exit
    }

    func test_cleanAndSendEvents_custom_events() {
        var isSuccess = false
        var packetIncremented = false

        payloadSendingService.cleanAndSendEvents(
            clientKey: clientKey,
            screenName: "test",
            onPacketIncrement: {
                packetIncremented.toggle()
            },
            onSuccess: {
                isSuccess.toggle()
            },
            onFailure: { _ in },
            eventSubset: [NIDEvent(type: .advancedDevice)]
        )

        assert(packetIncremented)
        assert(isSuccess)

        assert(mockNetworkService.mockedRetryableRequestSuccess == 1)
        assert(mockNetworkService.mockedRetryableRequestFailure == 0)
    }

    func test_cleanAndSendEvents_custom_events_failure() {
        var isSuccess = true
        var packetIncremented = false

        mockNetworkService.mockRequestShouldFail = true

        payloadSendingService.cleanAndSendEvents(
            clientKey: clientKey,
            screenName: "test",
            onPacketIncrement: {
                packetIncremented.toggle()
            },
            onSuccess: {
                isSuccess = true
            },
            onFailure: { _ in
                isSuccess = false
            },
            eventSubset: [NIDEvent(type: .advancedDevice)]
        )

        assert(packetIncremented)
        assert(!isSuccess)

        assert(mockNetworkService.mockedRetryableRequestSuccess == 0)
        assert(mockNetworkService.mockedRetryableRequestFailure == 1)
    }

    func test_post_success() {
        var isSuccess = false

        payloadSendingService.post(
            screen: "testScreenName",
            clientKey: clientKey,
            events: [],
            onSuccess: {
                isSuccess.toggle()

            },
            onFailure: { _ in }
        )

        assert(mockNetworkService.mockedRetryableRequestSuccess == 1)
        assert(mockNetworkService.mockedRetryableRequestFailure == 0)
        assert(isSuccess)
    }

    func test_post_failure() {
        var isSuccess = true
        mockNetworkService.mockRequestShouldFail = true

        payloadSendingService.post(
            screen: "testScreenName",
            clientKey: clientKey,
            events: [],
            onSuccess: {},
            onFailure: { _ in
                isSuccess.toggle()
            }
        )

        assert(mockNetworkService.mockedRetryableRequestSuccess == 0)
        assert(mockNetworkService.mockedRetryableRequestFailure == 1)
        assert(!isSuccess)
    }
}
