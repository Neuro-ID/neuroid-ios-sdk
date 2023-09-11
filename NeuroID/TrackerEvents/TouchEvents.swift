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
    func observeTouchEvents(_ sender: UIControl) {
        sender.addTarget(self, action: #selector(controlTouchStart), for: .touchDown)
        sender.addTarget(self, action: #selector(controlTouchEnd), for: .touchUpInside)
        sender.addTarget(self, action: #selector(controlTouchMove), for: .touchUpOutside)
    }

    @objc func controlTouchStart(sender: UIView) {
        touchEvent(sender: sender, eventName: .touchStart)
    }

    @objc func controlTouchEnd(sender: UIView) {
        touchEvent(sender: sender, eventName: .touchEnd)
    }

    @objc func controlTouchMove(sender: UIView) {
        touchEvent(sender: sender, eventName: .touchMove)
    }

    func touchEvent(sender: UIView, eventName: NIDEventName) {
        let tg = ParamsCreator.getTgParams(
            view: sender,
            extraParams: ["sender": TargetValue.string(sender.className)])

        captureEvent(event: NIDEvent(type: eventName, tg: tg, view: sender))
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
    let location = gesture.location(in: gesture.view)

    var size: CGFloat = 0.0
    var force: CGFloat = 0.0
    if let touch = touches.first {
        if #available(iOS 9.0, *) {
            force = touch.force
        }

        size = touch.majorRadius
    }

    captureTouchEvent(type: type, view: gesture.view, location: location, extraAttr: ["size": "\(size)", "force": "\(force)"])
}

func captureTouchEvent(type: NIDEventName, view: UIView?, location: CGPoint, extraAttr: [String: String] = [:]) {
    let viewName = view?.id ?? "NO_TARGET"
    let viewClass = view?.className ?? "NO_TARGET_CLASS"

    let xCoordinate = location.x
    let yCoordinate = location.y

    if NeuroID.isStopped() {
        return
    }

    let tg: [String: TargetValue] = [
        "\(Constants.tgsKey.rawValue)": TargetValue.string(viewName),
        "\(Constants.etnKey.rawValue)": TargetValue.string(viewClass),
    ]

    var attrs: [Attrs] = [
        Attrs(n: "x", v: "\(xCoordinate)"),
        Attrs(n: "y", v: "\(yCoordinate)"),
    ]

    for (key, value) in extraAttr {
        attrs.append(Attrs(n: key, v: value))
    }

    let newEvent = NIDEvent(type: type, tg: tg)
    newEvent.tgs = viewName
    newEvent.attrs = attrs
    newEvent.touches = [
        NIDTouches(x: xCoordinate, y: yCoordinate),
    ]
    // Make sure we have a valid url set
    newEvent.url = NeuroID.getScreenName()
    DataStore.insertEvent(screen: viewClass, event: newEvent)
}
