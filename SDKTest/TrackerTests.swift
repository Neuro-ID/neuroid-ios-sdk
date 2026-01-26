//
//  TrackerTests.swift
//  NeuroID
//
//  Created by Collin Dunphy on 1/26/26.
//

import Testing
import UIKit

@testable import NeuroID

@MainActor
@Suite("TrackerTests")
struct TrackerTests {
    
    let clientKey = "key_test_123456"
    let userId = "form_mobilesandbox"
    let screenNameValue = "testScreen"
    let guidValue = "\(Constants.attrGuidKey.rawValue)"
    let tracker: NeuroIDTracker
    
    init() {
        let configuration = NeuroID.Configuration(clientKey: clientKey, isAdvancedDevice: false)
        _ = NeuroID.configure(configuration)
        self.tracker = NeuroIDTracker(screen: screenNameValue, controller: nil)
        NeuroID.shared._isSDKStarted = true
    }
    
    @Test
    func valueChanged() {
        let view = UIStepper(frame: CGRect(x: 0, y: 0, width: 120, height: 30))
        view.accessibilityIdentifier = "stepper-1"
        
        NeuroIDTracker.registerSingleView(v: view, screenName: screenNameValue, guid: guidValue, topDownHierarchyPath: "")

        tracker.valueChanged(sender: view)
        
        let events = NeuroID.shared.datastore.getAllEvents().filter { $0.type == "REGISTER_TARGET" }
        #expect(events.count == 1)
    }
}
