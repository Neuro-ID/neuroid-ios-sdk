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

    // function which is triggered when handleTap is called
    @objc static func neuroTextTouchListener() {
        print("Hello World")
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
            print("Slider")
        case is UISwitch:
            print("Switch")
        case is UITableViewCell:
            print("Table view cell")
        case is UIPickerView:
            let pv = v as! UIPickerView
            print("Picker")
        case is UIDatePicker:
            print("Date picker")

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

// MARK: - Properties - temporary public for testing

enum ParamsCreator {
    static func getTgParams(view: UIView, extraParams: [String: TargetValue] = [:]) -> [String: TargetValue] {
        // TODO, figure out if we need to find super class of ETN
        var params: [String: TargetValue] = ["tgs": TargetValue.string(view.id), "etn": TargetValue.string(view.className)]
        for (key, value) in extraParams {
            params[key] = value
        }
        return params
    }

    static func getTimeStamp() -> Int64 {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        return now
    }

    static func getTextTgParams(view: UIView, extraParams: [String: TargetValue] = [:]) -> [String: TargetValue] {
        var params: [String: TargetValue] = [
            "tgs": TargetValue.string(view.id),
            "etn": TargetValue.string(NIDEventName.textChange.rawValue),
            "kc": TargetValue.int(0),
        ]
        for (key, value) in extraParams {
            params[key] = value
        }
        return params
    }

    static func getTGParamsForInput(eventName: NIDEventName, view: UIView, type: String, extraParams: [String: TargetValue] = [:], attrParams: [String: Any]?) -> [String: TargetValue] {
        var params: [String: TargetValue] = [:]

        switch eventName {
        case NIDEventName.focus, NIDEventName.blur, NIDEventName.textChange, NIDEventName.radioChange, NIDEventName.checkboxChange, NIDEventName.input, NIDEventName.copy, NIDEventName.paste, NIDEventName.click:

//            var attrParams:Attr;
            var inputValue = attrParams?["v"] as? String ?? "S~C~~"
            var attrVal = Attr(n: "v", v: inputValue)

            var textValue = attrParams?["hash"] as? String ?? ""
            var hashValue = Attr(n: "hash", v: textValue.sha256().prefix(8).string)
            var attrArraryVal: [Attr] = [attrVal, hashValue]
            params = [
                "tgs": TargetValue.string(view.id),
                "etn": TargetValue.string(view.id),
                "et": TargetValue.string(type),
                "attr": TargetValue.attr(attrArraryVal),
            ]

        case NIDEventName.keyDown:
            params = [
                "tgs": TargetValue.string(view.id),
            ]
        default:
            print("Invalid type")
        }
        for (key, value) in extraParams {
            params[key] = value
        }
        return params
    }

    static func getUiControlTgParams(sender: UIView) -> [String: TargetValue] {
        var tg: [String: TargetValue] = ["sender": TargetValue.string(sender.className), "tgs": TargetValue.string(sender.id)]

        if let control = sender as? UISwitch {
            tg["oldValue"] = TargetValue.bool(!control.isOn)
            tg["newValue"] = TargetValue.bool(control.isOn)
        } else if let control = sender as? UISegmentedControl {
            tg["value"] = TargetValue.string(control.titleForSegment(at: control.selectedSegmentIndex) ?? "")
            tg["selectedIndex"] = TargetValue.int(control.selectedSegmentIndex)
        } else if let control = sender as? UIStepper {
            tg["value"] = TargetValue.double(control.value)
        } else if let control = sender as? UISlider {
            tg["value"] = TargetValue.double(Double(control.value))
        } else if let control = sender as? UIDatePicker {
            tg["value"] = TargetValue.string("\(control.date)")
        }
        return tg
    }

    static func getCopyTgParams() -> [String: TargetValue] {
        let val = UIPasteboard.general.string ?? ""
        return ["content": TargetValue.string(UIPasteboard.general.string ?? "")]
    }

    static func getOrientationChangeTgParams() -> [String: Any?] {
        let orientation: String
        if UIDevice.current.orientation.isLandscape {
            orientation = "Landscape"
        } else {
            orientation = "Portrait"
        }

        return ["orientation": orientation]
    }

    static func getDefaultSessionParams() -> [String: Any?] {
        let params = [
            "clientId": ParamsCreator.getClientId(),
            "environment": NeuroID.getEnvironment,
            "sdkVersion": ParamsCreator.getSDKVersion(),
            "pageTag": NeuroID.getScreenName,
            "responseId": ParamsCreator.generateUniqueHexId(),
            "siteId": NeuroID.siteId,
            "userId": ParamsCreator.getUserID() ?? nil,
        ] as [String: Any?]

        return params
    }

    static func getClientKey() -> String {
        guard let key = NeuroID.clientKey else {
            print("Error: clientKey is not set")
            return ""
        }
        return key
    }

//    static func createRequestId() -> String {
//        let epoch = 1488084578518
//        let now = Date().timeIntervalSince1970 * 1000
//        let rawId = (Int(now) - epoch) * 1024  + NeuroID.sequenceId
//        NeuroID.sequenceId += 1
//        return String(format: "%02X", rawId)
//    }

    // Sessions are created under conditions:
    // Launch of application
    // If user idles for > 30 min
    static func getSessionID() -> String {
        let sidName = "nid_sid"
        let sidExpires = "nid_sid_expires"
        let defaults = UserDefaults.standard
        let sid = defaults.string(forKey: sidName)

        // TODO: Expire sesions
        if sid != nil {
            return sid ?? ""
        }

        var id = UUID().uuidString
        print("Session ID:", id)
        return id
    }

    /**
     Sessions expire after 30 minutes
     */
    static func isSessionExpired() -> Bool {
        var expireTime = Int64(UserDefaults.standard.integer(forKey: "nid_sid_expires"))

        // If 0, that means we need to set expire time
        if expireTime == 0 {
            expireTime = setSessionExpireTime()
        }
        if ParamsCreator.getTimeStamp() >= expireTime {
            return true
        }
        return false
    }

    static func setSessionExpireTime() -> Int64 {
        let thrityMinutes: Int64 = 1800000
        let expiresTime = ParamsCreator.getTimeStamp() + thrityMinutes
        UserDefaults.standard.set(expiresTime, forKey: "nid_sid_expires")
        return expiresTime
    }

    static func getClientId() -> String {
        let clientIdName = "nid_cid"
        var cid = UserDefaults.standard.string(forKey: clientIdName)
        if NeuroID.clientId != nil {
            cid = NeuroID.clientId
        }
        // Ensure we aren't on old client id
        if cid != nil && !cid!.contains("_") {
            return cid!
        } else {
            cid = genId()
            NeuroID.clientId = cid
            UserDefaults.standard.set(cid, forKey: clientIdName)
            return cid!
        }
    }

    static func getTabId() -> String {
        let tabIdName = "nid_tid"
        var tid = UserDefaults.standard.string(forKey: tabIdName)

        if tid != nil && !tid!.contains("-") {
            return tid!
        } else {
            let randString = UUID().uuidString
            let tid = randString.replacingOccurrences(of: "-", with: "").prefix(12)
            UserDefaults.standard.set(tid, forKey: tabIdName)
            return "\(tid)"
        }
    }

    static func getUserID() -> String? {
        let nidUserID = "nid_user_id"
        return UserDefaults.standard.string(forKey: nidUserID)
    }

    static func getDeviceId() -> String {
        let deviceIdCacheKey = "nid_did"
        var did = UserDefaults.standard.string(forKey: deviceIdCacheKey)

        if did != nil && did!.contains("_") {
            return did!
        } else {
            did = genId()
            UserDefaults.standard.set(did, forKey: deviceIdCacheKey)
            return did!
        }
    }

    private static func genId() -> String {
        return UUID().uuidString
    }

    static func getDnt() -> Bool {
        let dntName = "nid_dnt"
        let defaults = UserDefaults.standard
        let dnt = defaults.string(forKey: dntName)
        // If there is ANYTHING set in nid_dnt, we return true (meaning don't track)
        if dnt != nil {
            return true
        } else {
            return false
        }
    }

    // Obviously, being a phone we always support touch
    static func getTouch() -> Bool {
        return true
    }

    static func getPlatform() -> String {
        return "Apple"
    }

    static func getLocale() -> String {
        return Locale.current.identifier
    }

    static func getUserAgent() -> String {
        return "iOS " + UIDevice.current.systemVersion
    }

    // Minutes from GMT
    static func getTimezone() -> Int {
        let timezone = TimeZone.current.secondsFromGMT() / 60
        return timezone
    }

    static func getLanguage() -> String {
        let locale = Locale.current.languageCode
        return locale ?? Locale.current.identifier
    }

    /** Start with primar JS version as TrackJS requires to force correct session structure */
    static func getSDKVersion() -> String {
        // Version MUST start with 4. in order to be processed correctly
        let version = Bundle(for: NeuroIDTracker.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return "5.ios-\(version ?? "?")"
    }

    static func getCommandQueueNamespace() -> String {
        return "nid"
    }

    static func generateUniqueHexId() -> String {
        let x = 1
        let now = Date().timeIntervalSince1970 * 1000
        let rawId = (Int(now) - 1488084578518) * 1024 + (x + 1)
        return String(format: "%02X", rawId)
    }
}

extension UIView {
    var className: String {
        return String(describing: type(of: self))
    }

    var subviewsDescriptions: [String] {
        return subviews.map { $0.description }
    }
}

extension UIViewController {
    var className: String {
        return String(describing: type(of: self))
    }
}

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
