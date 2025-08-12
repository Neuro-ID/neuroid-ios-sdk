//
//  NIDSendTests.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/10/25.
//
@testable import NeuroID
import XCTest

class NIDSendTests: XCTestCase {

    func test_initCollectionTimer_item() {
        NeuroID._isSDKStarted = false
        let expectation = XCTestExpectation(description: "Wait for 5 seconds")

        let workItem = DispatchWorkItem {
            NeuroID._isSDKStarted = true
            expectation.fulfill()
        }
        NeuroID.sendCollectionWorkItem = workItem

        NeuroID.initCollectionTimer()

        // Wait for the expectation to be fulfilled, or timeout after 7 seconds
        wait(for: [expectation], timeout: 7)

        assert(NeuroID._isSDKStarted)
        NeuroID._isSDKStarted = false
    }

    func test_initCollectionTimer_item_nil() {
        NeuroID._isSDKStarted = false
        let expectation = XCTestExpectation(description: "Wait for 5 seconds")

        // setting the item as nil so the queue won't run
        NeuroID.sendCollectionWorkItem = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            expectation.fulfill()
        }

        NeuroID.initCollectionTimer()

        // Wait for the expectation to be fulfilled, or timeout after 7 seconds
        wait(for: [expectation], timeout: 7)

        assert(!NeuroID._isSDKStarted)
        NeuroID._isSDKStarted = false
    }

    //    createCollectionWorkItem // Not sure how to test because it returns an item that always exists
}
