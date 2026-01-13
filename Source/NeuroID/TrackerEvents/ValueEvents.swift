//
//  ValueEvents.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

// MARK: - value events

extension NeuroIDTracker {
    func observeValueChanged(_ sender: UIControl) {
        sender.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    @objc func valueChanged(sender: UIView) {
        var eventName = NIDEventName.change
        var tg: [String: TargetValue] = ParamsCreator.getUiControlTgParams(sender: sender)

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

        } else if let _ = sender as? UIColorWell {
            eventName = .colorWellChange
        }

        let viewId = TargetValue.string(sender.id)
        tg["\(Constants.tgsKey.rawValue)"] = viewId

        captureEvent(event:
            NIDEvent(
                type: eventName,
                tg: tg,
                tgs: viewId.toString(),
                x: sender.frame.origin.x,
                y: sender.frame.origin.y,
                url: UtilFunctions.getFullViewlURLPath(
                    currView: sender
                )
            )
        )
    }
}
