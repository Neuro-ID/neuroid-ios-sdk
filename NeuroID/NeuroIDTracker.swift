import Alamofire
import CommonCrypto
import Foundation
import ObjectiveC
import os
import SwiftUI
import UIKit
import WebKit

// MARK: - NeuroIDTracker

public class NeuroIDTracker: NSObject {
    private var screen: String?
    private var className: String?
    private var createSessionEvent: NIDEvent?
    /// Capture letter count of textfield/textview to detect a paste action
    var textCapturing = [String: String]()
    public init(screen: String, controller: UIViewController?) {
        super.init()
        self.screen = screen
        if !NeuroID.isStopped() {
            subscribe(inScreen: controller)
        }
        className = controller?.className
    }

    public func captureEvent(event: NIDEvent) {
        if NeuroID.isStopped() {
            return
        }
        let screenName = screen ?? UUID().uuidString
        var newEvent = event
        // Make sure we have a valid url set
        newEvent.url = screenName
        DataStore.insertEvent(screen: screenName, event: newEvent)
    }

    func getCurrentSession() -> String? {
        return UserDefaults.standard.string(forKey: "nid_sid")
    }

    public static func getFullViewlURLPath(currView: UIView?, screenName: String) -> String {
        if currView == nil {
            return screenName
        }
        let parentView = currView!.superview?.className
        let grandParentView = currView!.superview?.superview?.className
        var fullViewString = ""
        if grandParentView != nil {
            fullViewString += "\(grandParentView ?? "")/"
            fullViewString += "\(parentView ?? "")/"
        } else if parentView != nil {
            fullViewString = "\(parentView ?? "")/"
        }
        fullViewString += screenName
        return fullViewString
    }

    public static func registerSingleView(v: Any, screenName: String, guid: String) {
        let screenName = NeuroID.getScreenName() ?? screenName
        let currView = v as? UIView

        NIDPrintLog("Registering view: \(screenName)")
        let fullViewString = NeuroIDTracker.getFullViewlURLPath(currView: currView, screenName: screenName)

        let attrVal = Attrs(n: "guid", v: guid)
        let shVal = Attrs(n: "screenHierarchy", v: fullViewString)
        let guidValue = Attr(n: "guid", v: guid)
        let attrValue = Attr(n: "screenHierarchy", v: fullViewString)

        switch v {
//        case is UIView:
//            let tfView = v as! UIView
//            let touchListener = UITapGestureRecognizer(target: tfView, action: #selector(self.neuroTextTouchListener(_:)))
//            tfView.addGestureRecognizer(touchListener)

        case is UITextField:
            let tfView = v as! UITextField
            NeuroID.registeredTargets.append(tfView.id)

//           @objc func myTargetFunction(textField: UITextField) {     print("myTargetFunction") }
//            // Add view on top of textfield to get taps
//            var invisView = UIView.init(frame: tfView.frame)
//            invisView.backgroundColor = UIColor(red: 100.0, green: 0.0, blue: 0.0, alpha: 0.0)
//
//            invisView.backgroundColor = UIColor(red: 0.8, green: 0.1, blue: 0.5, alpha: 1)
//            tfView.addSubview(invisView)
//            let tap = UITapGestureRecognizer(target: self , action: #selector(self.handleTap(_:)))
//            invisView.addGestureRecognizer(tap)
//            invisView.superview?.bringSubviewToFront(invisView)
//            invisView.superview?.layer.zPosition = 10000000

            let temp = getParentClasses(currView: currView, hierarchyString: "UITextField")

            var nidEvent = NIDEvent(eventName: NIDEventName.registerTarget, tgs: tfView.id, en: tfView.id, etn: "INPUT", et: "UITextField::\(tfView.className)", ec: screenName, v: "S~C~~\(tfView.placeholder?.count ?? 0)", url: screenName)
            nidEvent.hv = tfView.placeholder?.sha256().prefix(8).string
            nidEvent.tg = ["attr": TargetValue.attr([attrValue, guidValue])]
            nidEvent.attrs = [attrVal, shVal]

            NeuroID.saveEventToLocalDataStore(nidEvent)
        case is UITextView:
            let tv = v as! UITextView
            NeuroID.registeredTargets.append(tv.id)

            let temp = getParentClasses(currView: currView, hierarchyString: "UITextView")

            var nidEvent = NIDEvent(eventName: NIDEventName.registerTarget, tgs: tv.id, en: tv.id, etn: "INPUT", et: "UITextView::\(tv.className)", ec: screenName, v: "S~C~~\(tv.text?.count ?? 0)", url: screenName)
            nidEvent.hv = tv.text?.sha256().prefix(8).string
            nidEvent.tg = ["attr": TargetValue.attr([attrValue, guidValue])]
            nidEvent.attrs = [attrVal, shVal]

            NeuroID.saveEventToLocalDataStore(nidEvent)
        case is UIButton:
            let tb = v as! UIButton
            NeuroID.registeredTargets.append(tb.id)

            var nidEvent = NIDEvent(eventName: NIDEventName.registerTarget, tgs: tb.id, en: tb.id, etn: "BUTTON", et: "UIButton::\(tb.className)", ec: screenName, v: "S~C~~\(tb.titleLabel?.text?.count ?? 0)", url: screenName)
            nidEvent.hv = tb.titleLabel?.text?.sha256().prefix(8).string
            nidEvent.tg = ["attr": TargetValue.attr([attrValue, guidValue])]
            nidEvent.attrs = [attrVal, shVal]

            NeuroID.saveEventToLocalDataStore(nidEvent)
        case is UISlider:
            NIDPrintLog("Slider")
        case is UISwitch:
            NIDPrintLog("Switch")
        case is UITableViewCell:
            NIDPrintLog("Table view cell")
        case is UIPickerView:
            let pv = v as! UIPickerView
            NIDPrintLog("Picker")
        case is UIDatePicker:
            NIDPrintLog("Date picker")

            let dp = v as! UIDatePicker
            NeuroID.registeredTargets.append(dp.id)

            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd hh:mm:ss"
            let dpValue = df.string(from: dp.date)

            let temp = getParentClasses(currView: currView, hierarchyString: "UIDatePicker")

            var nidEvent = NIDEvent(eventName: NIDEventName.registerTarget, tgs: dp.id, en: dp.id, etn: "INPUT", et: "UIDatePicker::\(dp.className)", ec: screenName, v: "S~C~~\(dpValue.count)", url: screenName)
            nidEvent.hv = dpValue.sha256().prefix(8).string
            nidEvent.tg = ["attr": TargetValue.attr([attrValue, guidValue])]
            nidEvent.attrs = [attrVal, shVal]

            NeuroID.saveEventToLocalDataStore(nidEvent)
        default:
            return
                //        print("Unknown type", v)
        }
        // Text
        // Inputs
        // Checkbox/Radios inputs
    }
}

// MARK: - Private functions

private extension NeuroIDTracker {
    func subscribe(inScreen controller: UIViewController?) {
        // Early exit if we are stopped
        if NeuroID.isStopped() {
            return
        }
        if let views = controller?.view.subviews {
            observeViews(views)
        }

        // Only run observations on first run
        if !NeuroID.observingInputs {
            NeuroID.observingInputs = true
            observeTextInputEvents()
            observeAppEvents()
            observeRotation()
        }
    }

    func observeViews(_ views: [UIView]) {
        for v in views {
            if let sender = v as? UIControl {
                observeTouchEvents(sender)
                observeValueChanged(sender)
            }
            if v.subviews.isEmpty == false {
                observeViews(v.subviews)
                continue
            }
        }
    }
}

//// MARK: - Pasteboard events
// private extension NeuroIDTracker {
//    func observePasteboard() {
//        NotificationCenter.default.addObserver(self, selector: #selector(contentCopied), name: UIPasteboard.changedNotification, object: nil)
//    }
//
//    @objc func contentCopied(notification: Notification) {
//        captureEvent(event: NIDEvent(type: NIDEventName.copy, tg: ParamsCreator.getCopyTgParams(), view: NeuroID.activeView))
//    }
// }

/***
 Anytime a view loads
 Check child subviews for eligible form events
 Form all eligible form events, check to see if they have a valid identifier and set one
 Register form events
 */

private func getParentClasses(currView: UIView?, hierarchyString: String?) -> String? {
    var newHieraString = "\(currView?.className ?? "UIView")"

    if hierarchyString != nil {
        newHieraString = "\(newHieraString)\\\(hierarchyString!)"
    }

    if currView?.superview != nil {
        getParentClasses(currView: currView?.superview, hierarchyString: newHieraString)
    }
    return newHieraString
}

// extension NSError {
//    convenience init(message: String) {
//        self.init(domain: message, code: 0, userInfo: nil)
//    }
//
//    fileprivate static func errorSwizzling(_ obj: NSError.Type,
//                                           originalSelector: Selector,
//                                           swizzledSelector: Selector) {
//        let originalMethod = class_getInstanceMethod(obj, originalSelector)
//        let swizzledMethod = class_getInstanceMethod(obj, swizzledSelector)
//
//        if let originalMethod = originalMethod,
//           let swizzledMethod = swizzledMethod {
//            method_exchangeImplementations(originalMethod, swizzledMethod)
//        }
//    }
//
//    fileprivate static func startSwizzling() {
//        let obj = NSError.self
//        errorSwizzling(obj,
//                       originalSelector: #selector(obj.init(domain:code:userInfo:)),
//                       swizzledSelector: #selector(obj.neuroIDInit(domain:code:userInfo:)))
//    }
//
//    @objc fileprivate func neuroIDInit(domain: String, code: Int, userInfo dict: [String: Any]? = nil) {
//        let tg: [String: Any?] = [
//            "domain": domain,
//            "code": code,
//            "userInfo": userInfo
//        ]
//        NeuroID.captureEvent(NIDEvent(type: .error, tg: tg, view: nil))
//        self.neuroIDInit(domain: domain, code: code, userInfo: userInfo)
//    }
// }

// extension Collection where Iterator.Element == [String: Any?] {
//    func toJSONString() -> String {
//    if let arr = self as? [[String: Any]],
//       let dat = try? JSONSerialization.data(withJSONObject: arr),
//       let str = String(data: dat, encoding: String.Encoding.utf8) {
//      return str
//    }
//    return "[]"
//  }
// }

extension LosslessStringConvertible {
    var string: String { .init(self) }
}

/** End base64 block */

func NIDPrintLog(_ strings: Any...) {
    if NeuroID.isStopped() {
        return
    }
    if NeuroID.logVisible {
        Swift.print(strings)
    }
}

extension Optional where Wrapped: Collection {
    var isEmptyOrNil: Bool {
        guard let value = self else { return true }
        return value.isEmpty
    }
}
