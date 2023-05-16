//
//  CustomEvents.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

// MARK: - Custom events

public extension NeuroIDTracker {
    static func registerViewIfNotRegistered(view: UIView) -> Bool {
        if !NeuroID.registeredTargets.contains(view.id) {
            NeuroID.registeredTargets.append(view.id)
            let guid = UUID().uuidString
            NeuroIDTracker.registerSingleView(v: view, screenName: NeuroID.getScreenName() ?? view.className, guid: guid, rts: true)
            return true
        }
        return false
    }

    func captureEventCheckBoxChange(isChecked: Bool, checkBox: UIView) {
        let tg = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.checkboxChange, view: checkBox, type: "UIView", attrParams: nil)
        let event = NIDEvent(type: .checkboxChange, tg: tg, v: String(isChecked))
        captureEvent(event: event)
    }

    func captureEventRadioChange(isChecked: Bool, radioButton: UIView) {
        let tg = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.radioChange, view: radioButton, type: "UIView", attrParams: nil)
        captureEvent(event: NIDEvent(type: .radioChange, tg: tg, v: String(isChecked)))
    }

    func captureEventSubmission(_ params: [String: TargetValue]? = nil) {
        captureEvent(event: NIDEvent(type: .formSubmit, tg: params, view: nil))
        captureEvent(event: NIDEvent(type: .applicationSubmit, tg: params, view: nil))
        captureEvent(event: NIDEvent(type: .pageSubmit, tg: params, view: nil))
    }

    func captureEventSubmissionSuccess(_ params: [String: TargetValue]? = nil) {
        captureEvent(event: NIDEvent(type: .formSubmitSuccess, tg: params, view: nil))
        captureEvent(event: NIDEvent(type: .applicationSubmitSuccess, tg: params, view: nil))
    }

    func captureEventSubmissionFailure(error: Error, params: [String: TargetValue]? = nil) {
        var newParams = params ?? [:]
        newParams["error"] = TargetValue.string(error.localizedDescription)
        captureEvent(event: NIDEvent(type: .formSubmitFailure, tg: newParams, view: nil))
        captureEvent(event: NIDEvent(type: .applicationSubmitFailure, tg: newParams, view: nil))
    }

    func excludeViews(views: UIView...) {
        for v in views {
            NeuroID.secretViews.append(v)
        }
    }
}
