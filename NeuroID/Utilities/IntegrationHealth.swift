//
//  IntegrationHealth.swift
//  NeuroID
//
//  Created by Kevin Sites on 4/20/23.
//

import Foundation
import UIKit

func filterEventsByType(_ events: [NIDEvent], _ type: String) -> [NIDEvent] {
    return events.filter { $0.type == type }
}

func formatDate(date: Date, dashSeparator: Bool = false) -> String {
    let df = DateFormatter()
    let timeFormat = dashSeparator ? "hh-mm-ss" : "hh:mm:ss"
    df.dateFormat = "yyyy-MM-dd \(timeFormat)"
    let now = df.string(from: date)

    return now
}

func generateIntegrationHealthReport() {
    let events = NeuroID.getIntegrationHealthEvents()
//    let events: [NIDEvent] = generateEvents()

    let fileName = "\(formatDate(date: Date(), dashSeparator: true))-integration.html"

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    print("**** event count \(events.count)")

    writeNIDEventsToJSON(Contstants.integrationHealthFile.rawValue, items: events)
}

// TESTING FUNCTIONS ONLY
func generateEvents() -> [NIDEvent] {
    let textControl = UITextField()
    textControl.accessibilityIdentifier = "text 1"
    textControl.text = "test Text"

    let textControl2 = UITextField()
    textControl2.accessibilityIdentifier = "text 2"
    textControl2.text = "test Text 2"

    let events = [generateEvent(textControl), generateEvent(textControl, NIDEventName.input),
                  generateEvent(textControl, NIDEventName.textChange), generateEvent(textControl, NIDEventName.registerTarget),
                  generateEvent(textControl, NIDEventName.applicationSubmit), generateEvent(textControl, NIDEventName.createSession),
                  generateEvent(textControl, NIDEventName.blur),

                  generateEvent(textControl2), generateEvent(textControl2, NIDEventName.input),
                  generateEvent(textControl2, NIDEventName.textChange), generateEvent(textControl2, NIDEventName.registerTarget),
                  generateEvent(textControl2, NIDEventName.applicationSubmit), generateEvent(textControl2, NIDEventName.createSession),
                  generateEvent(textControl2, NIDEventName.blur)]

    return events
}

func generateEvent(_ target: UIView, _ eventType: NIDEventName = NIDEventName.textChange) -> NIDEvent {
//    let textValue = target.text ?? ""
//    let lengthValue = "S~C~~\(target.text?.count ?? 0)"

    // Text Change
    let textChangeTG = ["tgs": TargetValue.string(target.id)]
    let textChangeEvent = NIDEvent(type: eventType, tg: textChangeTG)

    return textChangeEvent
}
