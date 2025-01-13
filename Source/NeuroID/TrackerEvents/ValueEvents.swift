//
//  ValueEvents.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

// MARK: - value events

internal extension NeuroIDTracker {
    func observeValueChanged(_ sender: UIControl) {
        sender.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    @objc func valueChanged(sender: UIView) {
        var eventName = NIDEventName.change
        let tg: [String: TargetValue] = ParamsCreator.getUiControlTgParams(sender: sender)

        if let _ = sender as? UISwitch {
            eventName = .selectChange

        } else if let _ = sender as? UISegmentedControl {
            eventName = .selectChange

        } else if let _ = sender as? UIStepper {
            eventName = .stepperChange

        } else if let _ = sender as? UISlider {
            eventName = .sliderChange

        } else if let _ = sender as? UIDatePicker {
            eventName = .inputChange

            // This is the only listener the UIDatePicker element will trigger, so we register here if not found
            _ = NeuroIDTracker.registerViewIfNotRegistered(view: sender)

        } else if #available(iOS 14.0, *) {
            if let _ = sender as? UIColorWell {
                eventName = .colorWellChange
            }
        }

        captureEvent(event: NIDEvent(type: eventName, tg: tg, view: sender))
    }
}
