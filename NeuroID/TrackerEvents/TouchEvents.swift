//
//  TouchEvents.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

// MARK: - Touch events

internal extension NeuroIDTracker {
    static func observeTouchEvents(_ sender: UIControl) {
        sender.addTarget(self, action: #selector(NeuroIDTracker.controlTouchStart), for: .touchDown)
        sender.addTarget(self, action: #selector(NeuroIDTracker.controlTouchEnd), for: .touchUpInside)
        sender.addTarget(self, action: #selector(NeuroIDTracker.controlTouchMove), for: .touchUpOutside)
    }

    @objc func controlTouchStart(sender: UIView) {
        NeuroID.activeView = sender
        NeuroIDTracker.touchEvent(sender: sender, eventName: .touchStart)
    }

    @objc func controlTouchEnd(sender: UIView) {
        NeuroIDTracker.touchEvent(sender: sender, eventName: .touchEnd)
    }

    @objc func controlTouchMove(sender: UIView) {
        NeuroIDTracker.touchEvent(sender: sender, eventName: .touchMove)
    }

    static func touchEvent(sender: UIView, eventName: NIDEventName) {
        if NeuroID.secretViews.contains(sender) { return }
        let tg = ParamsCreator.getTgParams(
            view: sender,
            extraParams: ["sender": TargetValue.string(sender.className)])

        captureEvent(event: NIDEvent(type: eventName, tg: tg, view: sender))
    }
}
