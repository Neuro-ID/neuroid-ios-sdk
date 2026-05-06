//
//  TouchEvents.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

// MARK: - Touch events

extension NeuroIDTracker {
    func observeTouchEvents(_ sender: UIControl) {
        sender.addTarget(self, action: #selector(controlTouchStart), for: .touchDown)
        sender.addTarget(self, action: #selector(controlTouchEnd), for: .touchUpInside)
        sender.addTarget(self, action: #selector(controlTouchMove), for: .touchUpOutside)
    }

    @objc func controlTouchStart(sender: UIView, forEvent event: UIEvent) {
        touchEvent(sender: sender, eventName: .touchStart, event: event)
    }

    @objc func controlTouchEnd(sender: UIView, forEvent event: UIEvent) {
        touchEvent(sender: sender, eventName: .touchEnd, event: event)
    }

    @objc func controlTouchMove(sender: UIView, forEvent event: UIEvent) {
        touchEvent(sender: sender, eventName: .touchMove, event: event)
    }

    func touchEvent(sender: UIView, eventName: NIDEventName, event: UIEvent) {
        let touchArray = UtilFunctions.extractTouchesFromEvent(uiView: sender, event: event)

        captureEvent(event:
            UtilFunctions.createTouchEvent(
                sender: sender,
                eventName: eventName,
                location: "UIControlSwizzle",
                touches: touchArray
            )
        )
    }
}

class CustomTapGestureRecognizer: UITapGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        captureTouchInfo(gesture: self, touches: touches, type: NIDEventName.customTouchStart)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)

        captureTouchInfo(gesture: self, touches: touches, type: NIDEventName.customTouchEnd)
    }
}

func captureTouchInfo(gesture: UITapGestureRecognizer, touches: Set<UITouch>, type: NIDEventName) {
    var size: CGFloat = 0.0
    var force: CGFloat = 0.0
    if let touch = touches.first {
        force = touch.force
        size = touch.majorRadius
    }

    captureTouchEvent(
        type: type,
        gestureRecognizer: gesture,
        extraAttr: ["size": "\(size)", "force": "\(force)"]
    )
}

func captureTouchEvent(
    type: NIDEventName,
    gestureRecognizer: UIGestureRecognizer,
    extraAttr: [String: String] = [:]
) {
    if NeuroID.isStopped() {
        return
    }

    let viewName = gestureRecognizer.view?.id ?? "NO_TARGET"
    let viewClass = gestureRecognizer.view?.nidClassName ?? "NO_TARGET_CLASS"

    let touchArray = UtilFunctions.extractTouchesFromGestureRecognizer(
        gestureRecognizer: gestureRecognizer
    )

    let tg: [String: TargetValue] = [
        "\(Constants.tgsKey.rawValue)": TargetValue.string(viewName),
        "\(Constants.etnKey.rawValue)": TargetValue.string(viewClass),
        "location": TargetValue.string("gestureRecognizer"),
    ]

    var attrs: [Attrs] = []
    for (key, value) in extraAttr {
        attrs.append(Attrs(n: key, v: value))
    }

    NeuroIDCore.shared.saveEventToLocalDataStore(
        NIDEvent(
            type: type,
            tg: tg,
            tgs: viewName,
            url: NeuroID.getScreenName(),
            attrs: attrs,
            touches: touchArray
        ),
        screen: viewClass
    )
}
