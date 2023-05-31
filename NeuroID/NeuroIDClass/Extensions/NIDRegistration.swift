//
//  NIDRegistration.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation
import UIKit

public extension NeuroID {
    static func excludeViewByTestID(excludedView: String) {
        NIDPrintLog("Exclude view called - \(excludedView)")
        NeuroID.excludedViewsTestIDs.append(excludedView)
    }

    /** Public API for manually registering a target. This should only be used when automatic fails. */
    static func manuallyRegisterTarget(view: UIView) {
        let screenName = view.id
        let guid = UUID().uuidString
        NIDPrintLog("Registering single view: \(screenName)")
        NeuroIDTracker.registerSingleView(v: view, screenName: screenName, guid: guid)
        let childViews = view.subviewsRecursive()
        for _view in childViews {
            NIDPrintLog("Registering subview Parent: \(screenName) Child: \(_view)")
            NeuroIDTracker.registerSingleView(v: _view, screenName: screenName, guid: guid)
        }
    }

    /** React Native API for manual registration */
    static func manuallyRegisterRNTarget(id: String, className: String, screenName: String, placeHolder: String) -> NIDEvent {
        let guid = UUID().uuidString
        let fullViewString = NeuroIDTracker.getFullViewlURLPath(currView: nil, screenName: screenName)
        var nidEvent = NIDEvent(eventName: NIDEventName.registerTarget, tgs: id, en: id, etn: "INPUT", et: "\(className)", ec: screenName, v: "\(Constants.eventValuePrefix.rawValue)\(placeHolder.count)", url: screenName)
        nidEvent.hv = placeHolder.sha256().prefix(8).string
        let attrVal = Attrs(n: "guid", v: guid)
        // Screen hierarchy
        let shVal = Attrs(n: "screenHierarchy", v: fullViewString)
        let guidValue = Attr(n: "guid", v: guid)
        let attrValue = Attr(n: "screenHierarchy", v: fullViewString)
        nidEvent.tg = ["attr": TargetValue.attr([attrValue, guidValue])]
        nidEvent.attrs = [attrVal, shVal]
        NeuroID.saveEventToLocalDataStore(nidEvent)
        return nidEvent
    }
}
