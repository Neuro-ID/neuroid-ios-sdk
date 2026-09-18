//
//  OrientationObserverTests.swift
//  NeuroID
//

import Testing
import UIKit

@testable import NeuroID

@MainActor
@Suite
struct OrientationObserverTests {
    let dataStore: DataStore

    init() {
        dataStore = DataStore()
        NeuroIDCore.shared.datastore = dataStore
    }

    @Test
    func observeOrientation() async {
        NeuroIDCore.shared.observingInputs = false
        NeuroIDCore.shared._isSDKStarted = true

        let uiControllerBasic = UIViewController()
        let input = UITextField()

        uiControllerBasic.view.addSubview(input)

        let tracker = NeuroIDTracker(
            screen: "test",
            controller: uiControllerBasic
        )

        tracker.observeRotation()
        tracker.deviceRotated(notification: Notification(name: UIDevice.orientationDidChangeNotification))

        let events = dataStore.getAndRemoveAllEvents()

        #expect(events.count == 2)
        #expect(
            events.map { $0.type } == [
                NIDEventName.windowOrientationChange.rawValue, NIDEventName.deviceOrientation.rawValue
            ]
        )
    }

    @Test
    func testMapping() {
        #expect(ParamsCreator.getOrientation(UIDeviceOrientation.faceDown) == "Flat")
        #expect(ParamsCreator.getOrientation(UIDeviceOrientation.faceUp) == "Flat")
        #expect(ParamsCreator.getOrientation(UIDeviceOrientation.portrait) == "Portrait")
        #expect(ParamsCreator.getOrientation(UIDeviceOrientation.portraitUpsideDown) == "Portrait")
        #expect(ParamsCreator.getOrientation(UIDeviceOrientation.landscapeLeft) == "Landscape")
        #expect(ParamsCreator.getOrientation(UIDeviceOrientation.landscapeRight) == "Landscape")
    }
}
