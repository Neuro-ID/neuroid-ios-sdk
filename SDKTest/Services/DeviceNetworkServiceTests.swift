//
//  DeviceNetworkServiceTests.swift
//  SDKTest
//

import Foundation
import Testing

@testable import NeuroID

struct DeviceNetworkServiceTests {
    let now = Date()

    // Builds a "D+N" style event id with the timestamp offset by `secondsAgo` from `now`,
    // matching the format produced by the ADV service.
    func eventId(secondsAgo: TimeInterval) -> String {
        let timestamp = now.addingTimeInterval(-secondsAgo)
        return "\(Int(timestamp.timeIntervalSince1970 * 1000)).suffix"
    }

    @Test("Returns nil when event id is not parseable")
    func checkEventIdNilWhenNotParseable() {
        let result = NeuroIDCore.shared.checkEventId(from: "not-a-timestamp", now: now)
        #expect(result == nil)
    }

    @Test("Valid and should send when well within cache window")
    func checkEventIdValidWhenWellWithinCacheWindow() {
        let result = NeuroIDCore.shared.checkEventId(
            from: eventId(secondsAgo: 0),
            now: now,
            cacheValidity: 100,
            maxAge: 1000
        )
        #expect(result?.isValid == true)
        #expect(result?.shouldSend == true)
    }

    @Test("Not valid but should send when just past cache validity")
    func checkEventIdShouldSendWhenJustPastCacheValidity() {
        let result = NeuroIDCore.shared.checkEventId(
            from: eventId(secondsAgo: 100),
            now: now,
            cacheValidity: 100,
            maxAge: 1000
        )
        #expect(result?.isValid == false)
        #expect(result?.shouldSend == true)
    }

    @Test("Not valid but should send when well within max age")
    func checkEventIdShouldSendWhenWellWithinMaxAge() {
        let result = NeuroIDCore.shared.checkEventId(
            from: eventId(secondsAgo: 500),
            now: now,
            cacheValidity: 100,
            maxAge: 1000
        )
        #expect(result?.isValid == false)
        #expect(result?.shouldSend == true)
    }

    @Test("Not valid and should not send when at max age")
    func checkEventIdShouldNotSendWhenAtMaxAge() {
        let result = NeuroIDCore.shared.checkEventId(
            from: eventId(secondsAgo: 1000),
            now: now,
            cacheValidity: 100,
            maxAge: 1000
        )
        #expect(result?.isValid == false)
        #expect(result?.shouldSend == false)
    }

    @Test("Not valid and should not send when well past max age")
    func checkEventIdShouldNotSendWhenWellPastMaxAge() {
        let result = NeuroIDCore.shared.checkEventId(
            from: eventId(secondsAgo: 5000),
            now: now,
            cacheValidity: 100,
            maxAge: 1000
        )
        #expect(result?.isValid == false)
        #expect(result?.shouldSend == false)
    }

    @Test("Returns the event id that was passed in")
    func checkEventIdReturnsEventId() {
        let storedEventId = eventId(secondsAgo: 10)
        let result = NeuroIDCore.shared.checkEventId(
            from: storedEventId,
            now: now,
            cacheValidity: 100,
            maxAge: 1000
        )
        #expect(result?.eventId == storedEventId)
    }
}
