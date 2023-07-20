//
//  Utils.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/30/23.
//

import Foundation
import UIKit

internal func captureContextMenuAction(type: NIDEventName, view: UIView, text: String?, className: String?) {
    if NeuroID.isStopped() {
        return
    }

    let lengthValue = "\(Constants.eventValuePrefix.rawValue)\(text?.count ?? 0)"
    let hashValue = text?.hashValue() ?? ""
    let pasteTG = ParamsCreator.getTGParamsForInput(
        eventName: type,
        view: view,
        type: type.rawValue,
        attrParams: ["v": lengthValue, "hash": text ?? ""]
    )

    let inputEvent = NIDEvent(type: type, tg: pasteTG)

    inputEvent.v = lengthValue
    inputEvent.hv = hashValue
    inputEvent.tgs = view.id

    let screenName = className ?? UUID().uuidString
    // Make sure we have a valid url set
    inputEvent.url = screenName
    DataStore.insertEvent(screen: screenName, event: inputEvent)
}
