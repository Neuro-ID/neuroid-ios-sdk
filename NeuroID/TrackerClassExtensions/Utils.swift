//
//  Utils.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/30/23.
//

import Foundation
import UIKit

internal func neuroIDPasteUtil(caller: UIResponder, view: UIView, text: String?, className: String?) {
//    neuroIDPasteUtil(caller: caller, view: view, text: text, className: className)
    if NeuroID.isStopped() {
        return
    }
    let lengthValue = "S~C~~\(text?.count ?? 0)"
    let pasteTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.paste, view: view, type: NIDEventName.paste.rawValue, attrParams: ["v": lengthValue, "hash": text ?? ""])
    let inputEvent = NIDEvent(type: NIDEventName.paste, tg: pasteTG)

    let screenName = className ?? UUID().uuidString
    var newEvent = inputEvent
    // Make sure we have a valid url set
    newEvent.url = screenName
    DataStore.insertEvent(screen: screenName, event: newEvent)
}
