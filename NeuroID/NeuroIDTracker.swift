import Foundation
import UIKit
import os
import WebKit

public struct NeuroID {

    fileprivate static var sequenceId = 1
    fileprivate static var clientKey: String?
    fileprivate static let sessionId: String = ParamsCreator.getSessionID()
    fileprivate static let clientId: String = ParamsCreator.getClientId()
    fileprivate static var userId: String?
    private static let SEND_INTERVAL: Double = 5
    fileprivate static var trackers = [String: NeuroIDTracker]()
    fileprivate static var secrectViews = [UIView]()
    fileprivate static let showDebugLog = false
    
    fileprivate static let localStorageNIDStopAll = "nid_stop_all"

    /// Turn on/off printing the SDK log to your console
    public static var logVisible = true
    
    

    // MARK: - Setup
    /// 1. Configure the SDK
    /// 2. Setup silent running loop
    /// 3. Send cached events from DB every `SEND_INTERVAL`
    public static func configure(clientKey: String) {
        if NeuroID.clientKey != nil {
            print("NeuroID Error: You already configured the SDK")
        }
        NeuroID.clientKey = clientKey
        
        let key = "nid_key";
        let defaults = UserDefaults.standard
        defaults.set(clientKey, forKey: key)
    }
    
    public static func stop(){
        UserDefaults.standard.set(true, forKey: localStorageNIDStopAll)
    }
    
    public static func clearSession(){
        UserDefaults.standard.set(nil, forKey: "nid_sid")
    }
    // When start is called, enable swizzling, as well as dispatch queue to send to API
    public static func start(){
        UserDefaults.standard.set(false, forKey: localStorageNIDStopAll)
        swizzle()
        
        
        #if DEBUG
        if NSClassFromString("XCTest") == nil {
            initTimer()
        }
        #else
        initTimer()
        #endif
    }
    
    public static func isStopped() -> Bool{
        let key = UserDefaults.standard.bool(forKey: localStorageNIDStopAll);
        if (key){
            return true
        }
        return false
    }
    
    public static func getBaseURL() -> String {
    //    let URL_PLIST_KEY = "NeuroURL"
    //    guard let rootUrl = Bundle.infoPlistValue(forKey: URL_PLIST_KEY) as? String else { return ""}
    //    var baseUrl: String {
    //        return rootUrl + "/v3/c"
    //    }
    //    return baseUrl;
//        return "http://localhost:9090";
//        return "https://7dc9-174-94-156-120.ngrok.io"
        return "https://api.usw2-dev1.nidops.net";
    }

    
    static func getClientKeyFromLocalStorage() -> String {
        let keyName = "nid_key";
        let defaults = UserDefaults.standard
        let key = defaults.string(forKey: keyName);
        
        return key ?? ""
    }
    
    private static func swizzle() {
        UIViewController.startSwizzling()
        UINavigationController.swizzleNavigation()
    }
    private static func initTimer() {
        // Send up the first payload, and then setup a repeating timer
        self.send()
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + SEND_INTERVAL) {
            self.send()
            self.initTimer()
        }
    }
    /**
     Publically exposed just for testing. This should not be any reason to call this directly.
     */
    public static func send() {
        logInfo(category: "APICall", content: "Sending to API")
        DispatchQueue.global(qos: .utility).async {
            groupAndPOST()
        }
    }
    
    /**
     Publically exposed just for testing. This should not be any reason to call this directly.
     */
    public static func groupAndPOST() {
        let dataStoreEvents = DataStore.getAllEvents()
        if dataStoreEvents.isEmpty { return }
        // Group by screen, and send to API
        let groupedEvents = Dictionary(grouping: dataStoreEvents, by: { (element: NIDEvent) in
            return element.url
        })
        
        for key in groupedEvents.keys {
//                let eventsAsDicts = groupedEvents[key]?.toArrayOfDicts()
//                if (eventsAsDicts.isEmptyOrNil){
//                    continue
//                }
            post(events: groupedEvents[key] ?? [], screen: key ?? "", onSuccess: { _ in
                logInfo(category: "APICall", content: "Sending successfully")
                    // send success -> delete
                }, onFailure: { error in
                    logError(category: "APICall", content: String(describing: error))
                })
        }
        // TODO, add more sophisticated removal of events (in case of failure)
        DataStore.removeSentEvents()
    }

    /// Direct send to API to create session
    /// Regularly send in loop
    fileprivate static func post(events: [NIDEvent],
                                 screen: String,
                                 onSuccess: @escaping(Any) -> Void,
                                 onFailure: @escaping(Error) -> Void) {
        guard let url = URL(string: NeuroID.getBaseURL() + "/v3/c") else {
            logError(content: "NeuroID base URL found")
            return
        }
        guard let clientKey = clientKey else {
            logError(content: "NeuroID client key not setup")
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(clientKey)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        
        let encoder = JSONEncoder()
        var jsonData:Data;
        do {
            jsonData = try encoder.encode(events)
        }catch{
            
            return
        }
        let jsonEvents:String = String(data: jsonData,
                                       encoding: .utf8) ?? ""
//        let jsonEvents: String = events.toJSONString()
        let base64Events: String = Data(jsonEvents.utf8).base64EncodedString()
        var params = ParamsCreator.getDefaultSessionParams()
        
        params["events"] = base64Events
        params["url"] = screen
        
        // Unwrap all optionals and convert to null if empty
        var unwrappedParams: [String: Any] = [:]
        for (key, value) in params {
           let newValue = value ?? "null"
            unwrappedParams[key] = newValue
        }
        
        let dataString = unwrappedParams.percentEncoded();
        
        guard let data = dataString.data(using: .utf8) else { return }
        request.httpBody = data

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let response = response as? HTTPURLResponse,
                  error == nil else {
                NIDPrintLog("error", error ?? "Unknown error")
//                onFailure(error ?? NSError(message: "Unknown"))
                return
            }

            let responseDict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            NIDPrintLog(responseDict as Any)

            guard (200 ... 299) ~= response.statusCode else {
                NIDPrintLog("statusCode: ", response.statusCode)
                onFailure(error ?? NSError(domain: "unknown", code: response.statusCode, userInfo: nil))
                return
            }

            if response.statusCode >= 200 && response.statusCode < 299 {
                onSuccess("success")
                return
            }

            guard let responseObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
                NIDPrintLog("Can't decode")
//                onFailure(NSError(message: "Can't decode"))
                return
            }
            onSuccess(responseObject)
        }

        task.resume()
    }

    public static func setUserID(_ userId: String) {
        UserDefaults.standard.set(userId, forKey: "nid_user_id")
        let setUserEvent = NIDEvent(session: NIDSessionEventName.setUserId, uid: userId);
        captureEvent(setUserEvent)
    }
    public static func logInfo(category: String = "default", content: Any...) {
        osLog(category: category, content: content, type: .info)
    }

    public static func logError(category: String = "default", content: Any...) {
        osLog(category: category, content: content, type: .error)
    }

    public static func logFault(category: String = "default", content: Any...) {
        osLog(category: category, content: content, type: .fault)
    }

    public static func logDebug(category: String = "default", content: Any...) {
        osLog(category: category, content: content, type: .debug)
    }

    public static func logDefault(category: String = "default", content: Any...) {
        osLog(category: category, content: content, type: .default)
    }

    private static func osLog(category: String = "default", content: Any..., type: OSLogType) {
        Log.log(category: category, contents: content, type: .info)
    }

    static func captureEvent(_ event: NIDEvent) {
//        guard let base64 = event.toBase64() else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            DataStore.insertEvent(screen: event.type, event: event)
        }
    }
}

extension NeuroID {
    static func cleanUpForTesting() {
        clientKey = nil
    }
}

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
        if (!NeuroID.isStopped() && getCurrentSession() == nil){
            self.createSessionEvent = createSession(screen: screen)
            subscribe(inScreen: controller)
        }
        className = controller?.className
    }

    public func captureEvent(event: NIDEvent) {
        NeuroID.logDebug(category: "saveEvent", content: event.toDict())
        let screenName = screen ?? UUID().uuidString
        DataStore.insertEvent(screen: screenName, event: event)
        NeuroID.logDebug(category: "saveEvent", content: "save event finish")
    }
    
    func getCurrentSession() -> String? {
        return UserDefaults.standard.string(forKey: "nid_sid")
    }
}

// MARK: - Custom events
public extension NeuroIDTracker {
    func captureEventCheckBoxChange(isChecked: Bool, checkBox: UIView) {
        let tg = ParamsCreator.getTgParams(view: checkBox)
        let event = NIDEvent(type: .checkboxChange, tg: tg, view: checkBox)
        captureEvent(event: event)
    }

    func captureEventRadioChange(isChecked: Bool, radioButton: UIView) {
        let tg = ParamsCreator.getTgParams(view: radioButton)
        captureEvent(event: NIDEvent(type: .radioChange, tg: tg, view: radioButton))
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
            NeuroID.secrectViews.append(v)
        }
    }
}

// MARK: - Private functions


extension Bundle {
    static func infoPlistValue(forKey key: String) -> Any? {
//        let infoPlistPath = Bundle.main.url(forResource: "Info", withExtension: "plist")
        
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) else {
            os_log("NeuroID Failed to find Plist");
           return nil
        }
        os_log("NeuroID config found");
        return value
    }
}

private extension NeuroIDTracker {
    func subscribe(inScreen controller: UIViewController?) {
        if let views = controller?.view.subviews {
            observeViews(views)
        }
        observeTextInputEvents()
        observeAppEvents()
        observePasteboard()
        observeRotation()
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

    func createSession(screen: String) -> NIDEvent {
        // TODO, return session if already exists
        let event = NIDEvent(session: .createSession, f: ParamsCreator.getClientKey(), siteId: nil, sid: ParamsCreator.getSessionID(), lsid: nil, cid: ParamsCreator.getClientId(), did: ParamsCreator.getDeviceId(), iid: ParamsCreator.getIntermediateId(), loc: ParamsCreator.getLocale(), ua: ParamsCreator.getUserAgent(), tzo: ParamsCreator.getTimezone(), lng: ParamsCreator.getLanguage(),p: ParamsCreator.getPlatform(), dnt: false, tch: ParamsCreator.getTouch(), url: screen, ns: ParamsCreator.getCommandQueueNamespace(), jsv: ParamsCreator.getSDKVersion())
        
        captureEvent(event: event)
        return event;
    }
}

// MARK: - Text control events
private extension NeuroIDTracker {
    func observeTextInputEvents() {
        // UITextField
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textBeginEditing),
                                               name: UITextField.textDidBeginEditingNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textChange),
                                               name: UITextField.textDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textEndEditing),
                                               name: UITextField.textDidEndEditingNotification,
                                               object: nil)

        // UITextView
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textBeginEditing),
                                               name: UITextView.textDidBeginEditingNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textChange),
                                               name: UITextView.textDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textEndEditing),
                                               name: UITextView.textDidEndEditingNotification,
                                               object: nil)

    }

    @objc func textBeginEditing(notification: Notification) {
        logTextEvent(from: notification, eventType: .focus)
    }

    @objc func textChange(notification: Notification) {
        // count the number of letters in 10ms (for instance) -> consider paste action
        logTextEvent(from: notification, eventType: .textChange)
    }

    @objc func textEndEditing(notification: Notification) {
        logTextEvent(from: notification, eventType: .blur)
    }

    func logTextEvent(from notification: Notification, eventType: NIDEventName) {
        if let textControl = notification.object as? UITextField {
            // isSecureText
            if textControl.textContentType == .password || textControl.isSecureTextEntry { return }
            if #available(iOS 12.0, *) {
                if textControl.textContentType == .newPassword { return }
            }

            let tg = ParamsCreator.getTextTgParams(view: textControl)
            detectPasting(view: textControl, text: textControl.text ?? "")
            captureEvent(event: NIDEvent(type: eventType, tg: tg, view: textControl))
        } else if let textControl = notification.object as? UITextView {
            if textControl.textContentType == .password || textControl.isSecureTextEntry { return }
            if #available(iOS 12.0, *) {
                if textControl.textContentType == .newPassword { return }
            }
            let tg = ParamsCreator.getTextTgParams(view: textControl)
            detectPasting(view: textControl, text: textControl.text ?? "")
            captureEvent(event: NIDEvent(type: eventType, tg: tg, view: nil))
        } else if let textControl = notification.object as? UISearchBar {
            let tg = ParamsCreator.getTextTgParams(view: textControl)
            detectPasting(view: textControl, text: textControl.text ?? "")
            captureEvent(event: NIDEvent(type: eventType, tg: tg, view: nil))
        }
    }

    func detectPasting(view: UIView, text: String) {
        let id = "\(Unmanaged.passUnretained(view).toOpaque())"
        let savedText = textCapturing[id] ?? ""
        let savedCount = savedText.count
        let newCount = text.count
        if newCount > 0 && newCount - savedCount > 2 {
            let tg = ParamsCreator.getTextTgParams(
                view: view,
                extraParams: ["etn": TargetValue.string(NIDEventName.input.rawValue)])
            captureEvent(event: NIDEvent(type: .paste, tg: tg, view: view))
        }
        textCapturing[id] = text
    }
}

// MARK: - Touch events
private extension NeuroIDTracker {
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
        if NeuroID.secrectViews.contains(sender) { return }
        let tg = ParamsCreator.getTgParams(
            view: sender,
            extraParams: ["sender": TargetValue.string(sender.className)])

        captureEvent(event: NIDEvent(type: eventName, tg: tg, view: nil))
    }
}

// MARK: - value events
private extension NeuroIDTracker {
    func observeValueChanged(_ sender: UIControl) {
        sender.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    @objc func valueChanged(sender: UIView) {
        var eventName = NIDEventName.change
        let tg: [String: TargetValue] = ParamsCreator.getUiControlTgParams(sender: sender)

        if let _ = sender as? UISwitch {
            eventName = .selectChange
        } else if let _ = sender as? UISegmentedControl {
            eventName = .selectChange
        } else if let _ = sender as? UIStepper {
            eventName = .change
        } else if let _ = sender as? UISlider {
            eventName = .sliderChange
        } else if let _ = sender as? UIDatePicker {
            eventName = .inputChange
        }

        captureEvent(event: NIDEvent(type: eventName, tg: tg, view: nil))
    }
}

// MARK: - App events
private extension NeuroIDTracker {
    private func observeAppEvents() {
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIScene.willDeactivateNotification, object: nil)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        }
    }

    @objc func appMovedToBackground() {
        captureEvent(event: NIDEvent(type: NIDEventName.userInactive, tg: nil, view: nil))
    }
}

// MARK: - Pasteboard events
private extension NeuroIDTracker {
    func observePasteboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(contentCopied), name: UIPasteboard.changedNotification, object: nil)
    }

    @objc func contentCopied() {
        captureEvent(event: NIDEvent(type: NIDEventName.copy, tg: ParamsCreator.getCopyTgParams(), view: nil))
    }
}

// MARK: - Device events
private extension NeuroIDTracker {
    func observeRotation() {
        NotificationCenter.default.addObserver(self, selector: #selector(deviceRotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    @objc func deviceRotated(notification: Notification) {
        let orientation: String
        if UIDevice.current.orientation.isLandscape {
            orientation = "Landscape"
        } else {
            orientation = "Portrait"
        }

        captureEvent(event: NIDEvent(type: NIDEventName.windowOrientationChange, tg: ["orientation": TargetValue.string(orientation)], view: nil))
        captureEvent(event: NIDEvent(type: NIDEventName.deviceOrientation, tg: ["orientation": TargetValue.string(orientation)], view: nil))
    }
}

// MARK: - Properties - temporary public for testing
struct ParamsCreator {
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
            "kc": TargetValue.int(0)
        ]
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
        return ["content": TargetValue.string(UIPasteboard.general.string!)]
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
            "key": NeuroID.clientKey,
            "id": ParamsCreator.createRequestId(),
            "siteId": nil,
            "sid": ParamsCreator.getSessionID(),
            "cid": ParamsCreator.getClientId(),
            "aid": nil,
            "did": ParamsCreator.getDeviceId(),
            "uid": ParamsCreator.getUserID() ?? nil,
            "pid": ParamsCreator.getPageId(),
            "iid": ParamsCreator.getIntermediateId(),
            "jsv": ParamsCreator.getSDKVersion()
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

    static func createRequestId() -> String {
        let epoch = 1488084578518
        let now = Date().timeIntervalSince1970 * 1000
        let rawId = (Int(now) - epoch) * 1024  + NeuroID.sequenceId
        NeuroID.sequenceId += 1
        return String(format: "%02X", rawId)
    }

    // Sessions are created under conditions:
    // Launch of application
    // If user idles for > 30 min
    static func getSessionID() -> String {
        let sidName =  "nid_sid"
        let defaults = UserDefaults.standard
        let sid = defaults.string(forKey: sidName)
        
        if (sid != nil && !isSessionExpired()) {
            return sid!;
        }

        var id = ""
        for _ in 0 ..< 16 {
            let digit = Int.random(in: 0..<10)
            id += "\(digit)"
            defaults.set(id, forKey: sidName)
        }
        print("Session ID:", id);
        return id
    }

    /**
     Sessions expire after 30 minutes
     */
    static func isSessionExpired() -> Bool {
        var expireTime = Int64(UserDefaults.standard.integer(forKey: "nid_sid_expires"));
        
        // If 0, that means we need to set expire time
        if (expireTime == 0) {
            expireTime = setSessionExpireTime();
        }
        if (ParamsCreator.getTimeStamp() >= expireTime){
            return true
        }
        return false
        
    }
    
    static func setSessionExpireTime() -> Int64 {
        let thrityMinutes: Int64 =  1800000
        let expiresTime = ParamsCreator.getTimeStamp() + thrityMinutes
        UserDefaults.standard.set(expiresTime, forKey: "nid_sid_expires")
        return expiresTime;
    }

    static func getClientId() -> String {
        let clientIdName = "nid_cid";
        var cid = UserDefaults.standard.string(forKey: clientIdName);
        
        if (cid != nil){
            return cid!;
        } else {
            cid = genId()
            UserDefaults.standard.set(cid, forKey: clientIdName)
            return cid!
        }
    }
    
    
    static func getUserID() -> String? {
        let nidUserID = "nid_user_id";
        return UserDefaults.standard.string(forKey: nidUserID);
    }
    
    static func getDeviceId() -> String {
        let deviceIdCacheKey = "nid_did";
        var did = UserDefaults.standard.string(forKey: deviceIdCacheKey);
        
        if (did != nil){
            return did!;
        } else {
            did = self.genId()
            UserDefaults.standard.set(did, forKey: deviceIdCacheKey)
            return did!
        }
    }
    
    static func getIntermediateId() -> String {
        let intermediateIdCacheKey = "nid_iid";
        var iid = UserDefaults.standard.string(forKey: intermediateIdCacheKey);
        
        if (iid != nil){
            return iid!;
        } else {
            iid = self.genId()
            UserDefaults.standard.set(iid, forKey: intermediateIdCacheKey)
            return iid!
        }
    }
    
    private static func genId() -> String {
        let now = Int(Date().timeIntervalSince1970 * 1000)
        let random = Int(Double.random(in: 0..<1) * Double(Int32.max))
        return "\(now).\(random)";
    }
    
    static func getDnt() -> Bool {
        let dntName = "nid_dnt";
        let defaults = UserDefaults.standard
        let dnt = defaults.string(forKey: dntName);
        // If there is ANYTHING set in nid_dnt, we return true (meaning don't track)
        if (dnt != nil)
        {
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

    /** Start with primar JS version as TrackJS requires to force correct session structure*/
    static func getSDKVersion() -> String {
        return "4.-ios-1.0.0"
    }
    
    static func getCommandQueueNamespace() -> String {
        return "nid";
    }

    static func getPageId() -> String {
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

private func registerSubViewsTargets(subViewControllers: [UIViewController]) -> [Any]{
    var registerViews = [Any]()
    for ctrls in subViewControllers {
        registerViews.append(ctrls.view)
        registerViews += ctrls.view.subviews
    }

    for v in registerViews {
        switch v {
        case is UITextField:
            let tfView = v as! UITextField
            NeuroID.captureEvent(NIDEvent(eventName: NIDEventName.registerTarget, tgs: tfView.id, en: tfView.id, etn: tfView.id, et: "", v: tfView.placeholder ?? ""))
        case is UITextView:
            let tv = v as! UITextView
            // TODO Checking for text might leak PII, skip default text for now.
            print("Text type")
        case is UIPickerView:
            let pv = v as! UIPickerView
            print("Picker")
        case is UIDatePicker:
            print("Date picker")
        case is UIButton:
            print("Button")
        case is UISlider:
            print("Slider")
        case is UISwitch:
            print("Switch")
        case is UITableViewCell:
            print("Table view cell")
            break
        default:
            print("Unknown type", v)
            return registerViews
        }
        // Text
        // Inputs
        // Checkbox/Radios inputs
        
        
    }
    return registerViews
}

private func swizzling(viewController: UIViewController.Type,
                       originalSelector: Selector,
                       swizzledSelector: Selector) {

    let originalMethod = class_getInstanceMethod(viewController, originalSelector)
    let swizzledMethod = class_getInstanceMethod(viewController, swizzledSelector)

    if let originalMethod = originalMethod,
       let swizzledMethod = swizzledMethod {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

// MARK: - Swizzling
extension UIViewController {
    private var ignoreLists: [String] {
        return [
            "UICompatibilityInputViewController",
            "UISystemKeyboardDockController",
            "UIInputWindowController",
            "UIPredictionViewController",
            "UIEditingOverlayViewController",
            "UISystemInputAssistantViewController"
        ]
    }

    @objc var neuroScreenName: String {
        return className
    }
    public var tracker: NeuroIDTracker? {
        if ignoreLists.contains(className) { return nil }
        if self is UINavigationController && className == "UINavigationController" { return nil }
        let tracker = NeuroID.trackers[className] ?? NeuroIDTracker(screen: neuroScreenName, controller: self)
        NeuroID.trackers[className] = tracker
        return tracker
    }

    public func captureEvent(event: NIDEvent) {
        if ignoreLists.contains(className) { return }
        var tg: [String: TargetValue] = event.tg ?? [:]
        tg["className"] = TargetValue.string(className)
        tg["title"] = TargetValue.string(title ?? "")
        
        // TODO Implement UIAlertController
//        if let vc = self as? UIAlertController {
//            tg["message"] = TargetValue.string(vc.message ?? "")
//            tg["actions"] = TargetValue.string(vc.actions.compactMap { $0.title }
//        }
//
//        if let eventName = NIDEventName(rawValue: event.type) {
//            let newEvent = NIDEvent(type: eventName, tg: tg, x: event.x, y: event.y)
//            tracker?.captureEvent(event: newEvent)
//        } else {
//            let newEvent = NIDEvent(customEvent: event.type, tg: tg, x: event.x, y: event.y)
            tracker?.captureEvent(event: event)
//        }
    }

    public func captureEvent(eventName: NIDEventName, params: [String: TargetValue]? = nil) {
        let event = NIDEvent(type: eventName, tg: params, view: self.view)
        captureEvent(event: event)
    }

    public func captureEventLogViewWillAppear(params: [String: TargetValue]) {
        captureEvent(eventName: .windowFocus, params: params)
    }

    public func captureEventLogViewDidLoad(params: [String: TargetValue]) {
        captureEvent(eventName: .windowLoad, params: params)
    }

    public func captureEventLogViewWillDisappear(params: [String: TargetValue]) {
        captureEvent(eventName: .windowBlur, params: params)
    }
}

private extension UIViewController {
    @objc static func startSwizzling() {
        let screen = UIViewController.self
    
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.viewWillAppear),
                  swizzledSelector: #selector(screen.neuroIDViewWillAppear))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.viewWillDisappear),
                  swizzledSelector: #selector(screen.neuroIDViewWillDisappear))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.viewDidLoad),
                  swizzledSelector: #selector(screen.neuroIDViewDidLoad))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.dismiss),
                  swizzledSelector: #selector(screen.neuroIDDismiss))
    }

    @objc func neuroIDViewWillAppear(animated: Bool) {
        self.neuroIDViewWillAppear(animated: animated)
        captureEvent(eventName: .windowFocus)
        
    }

    @objc func neuroIDViewWillDisappear(animated: Bool) {
        self.neuroIDViewWillDisappear(animated: animated)
        captureEvent(eventName: .windowBlur)
    }

    /**
        When overriding viewDidLoad in  controllers make sure that super is the last thing called in the function (so that we can accurately detect all added views/subviews)
    
          Anytime a view loads
          Check child subviews for eligible form events
          Form all eligible form events, check to see if they have a valid identifier and set one
          Register form events
     */
    @objc func neuroIDViewDidLoad() {
        self.neuroIDViewDidLoad()
        captureEvent(eventName: .windowLoad)
        var subViews = self.view.subviews
        var allViewControllers = self.children
        allViewControllers.append(self)
        registerSubViewsTargets(subViewControllers: allViewControllers)
    }

    @objc func neuroIDDismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        self.neuroIDDismiss(animated: flag, completion: completion)
        captureEvent(eventName: .windowUnload)
    }
}

extension UINavigationController {
    fileprivate static func swizzleNavigation() {
        let screen = UINavigationController.self
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.popViewController(animated:)),
                  swizzledSelector: #selector(screen.neuroIDPopViewController(animated:)))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.popToViewController(_:animated:)),
                  swizzledSelector: #selector(screen.neuroIDPopToViewController(_:animated:)))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.popToRootViewController),
                  swizzledSelector: #selector(screen.neuroIDPopToRootViewController))
    }

    @objc fileprivate func neuroIDPopViewController(animated: Bool) -> UIViewController? {
        captureEvent(eventName: .windowUnload)
        return self.neuroIDPopViewController(animated: animated)
    }

    @objc fileprivate func neuroIDPopToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        captureEvent(eventName: .windowUnload)
        return self.neuroIDPopToViewController(viewController, animated: animated)
    }

    @objc fileprivate func neuroIDPopToRootViewController(animated: Bool) -> [UIViewController]? {
        captureEvent(eventName: .windowUnload)
        return self.neuroIDPopToRootViewController(animated: animated)
    }
}

//extension NSError {
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
//}

extension String {
    func decodeBase64() -> [String: Any]? {
        guard let decodedData = Data(base64Encoded: self) else { return nil }

        do {
            let dict = try JSONSerialization.jsonObject(with: decodedData, options: .allowFragments)
            return dict as? [String: Any]
        } catch {
            return nil
        }

    }
}

//extension Collection where Iterator.Element == [String: Any?] {
//    func toJSONString() -> String {
//    if let arr = self as? [[String: Any]],
//       let dat = try? JSONSerialization.data(withJSONObject: arr),
//       let str = String(data: dat, encoding: String.Encoding.utf8) {
//      return str
//    }
//    return "[]"
//  }
//}
/** Base 64 Encode/Decoding
 */
extension StringProtocol {
    var data: Data { Data(utf8) }
    var base64Encoded: Data { data.base64EncodedData() }
    var base64Decoded: Data? { Data(base64Encoded: string) }
}
extension LosslessStringConvertible {
    var string: String { .init(self) }
}
extension Sequence where Element == UInt8 {
    var data: Data { .init(self) }
    var base64Decoded: Data? { Data(base64Encoded: data) }
    var string: String? { String(bytes: self, encoding: .utf8) }
}
/** End base64 block*/

func NIDPrintLog(_ strings: Any...) {
    if NeuroID.logVisible {
        Swift.print(strings)
    }
}

private struct Log {
    @available(iOS 10.0, *)
    static func log(category: String, contents: Any..., type: OSLogType) {
        #if DEBUG
        if NeuroID.showDebugLog {
            let message = contents.map { "\($0)"}.joined(separator: " ")
            os_log("NeuroID: %@", message)
        }
        #endif
    }
}

extension Double {
    func truncate(places : Int)-> Double {
        return Double(floor(pow(10.0, Double(places)) * self)/pow(10.0, Double(places)))
    }
}

public extension UIView {
    var id: String {
        get {
            // TODO insert generated ID
            return (accessibilityIdentifier.isEmptyOrNil) ? ("todo-id") : (accessibilityIdentifier!)
        }
        set {
            accessibilityIdentifier = newValue
        }
    }
}

public extension UIView {
    var label: String {
        get {
            return (accessibilityLabel.isEmptyOrNil) ? ("todo-label") : (accessibilityLabel!)
        }
        set {
            accessibilityLabel = newValue
        }
    }
}

extension Dictionary {
  func percentEncoded() -> String {
    return map { key, value in
      let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
      let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
      return escapedKey + "=" + escapedValue
    }
    .joined(separator: "&")
  }
}

extension CharacterSet {
  static let urlQueryValueAllowed: CharacterSet = {
    let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
    let subDelimitersToEncode = "!$&'()*+,;="

    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
    return allowed
  }()
}

extension Optional where Wrapped: Collection {
  var isEmptyOrNil: Bool {
    guard let value = self else { return true }
    return value.isEmpty
  }
}
