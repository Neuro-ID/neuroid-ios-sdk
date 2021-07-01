import Foundation
import UIKit
import os

public struct NeuroID {
    fileprivate static let rooUrl = "https://api.usw2-dev1.nidops.net"
    fileprivate static var baseUrl: String {
        return rooUrl + "/v3/c"
    }
    fileprivate static var sequenceId = 1
    fileprivate static var clientKey: String?
    fileprivate static let sessionId: String = ParamsCreator.createSessionId()
    fileprivate static let clientId: String = ParamsCreator.getClientId()
    fileprivate static var userId: String?
    private static let SEND_INTERVAL: Double = 5
    fileprivate static var trackers = [String: NeuroIDTracker]()
    fileprivate static var secrectViews = [UIView]()
    
    /// Turn on/off printing the SDK log to your console
    public static var logVisible = true
    
    // MARK: - Setup
    /// 1. Configure the SDK
    /// 2. Setup silent running loop
    /// 3. Send cached events from DB every `SEND_INTERVAL`
    public static func configure(clientKey: String, userId: String?) {
        if NeuroID.clientKey != nil {
            fatalError("You already configured the SDK")
        }
        NeuroID.clientKey = clientKey
        NeuroID.userId = userId
        if let userId = userId {
            setUserId(userId)
        }
        swizzle()
        
        #if DEBUG
        if NSClassFromString("XCTest") == nil {
            initTimer()
        }
        #else
        initTimer()
        #endif
        
        let tracker = NeuroIDTracker(screen: "AppDelegate", controller: nil)
        tracker.log(event: NIEvent(type: .windowLoad, tg: nil, x: nil, y: nil))
    }
    
    private static func swizzle() {
        UIViewController.startSwizzling()
        UINavigationController.swizzleNavigation()
        NSError.startSwizzling()
    }
    private static func initTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + SEND_INTERVAL) {
            self.send()
            self.initTimer()
        }
    }
    private static func send() {
        DispatchQueue.global(qos: .background).async {
            let dbResult = DB.shared.getAll()
            if dbResult.base64Strings.isEmpty { return }
            
            var params = ParamsCreator.getDefaultEventParams()
            params["url"] = dbResult.screen
            
            var events = [[String: Any]]()
            for string in dbResult.base64Strings {
                guard let dict = string.decodeBase64() else { continue }
                events.append(dict)
            }
            params["events"] = events.toBase64()
            
            post(params: params, onSuccess: { _ in
                // send success -> delete
                DB.shared.deleteSent()
            }, onFailure: { _ in
                
            })
        }
    }
    
    /// Direct send to API to create session
    /// Regularly send in loop
    fileprivate static func post(params: [String: Any?],
                                 onSuccess: @escaping(Any) -> Void,
                                 onFailure: @escaping(Error) -> Void) {
        guard let url = URL(string: NeuroID.baseUrl) else { return }
        guard let clientKey = clientKey else {
            fatalError("No client key setup")
        }
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(clientKey)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        
        var dataString = ""
        for (key, value) in params {
            let newValue = value ?? "null"
            dataString += "\(key)=\(newValue)&"
        }
        
        dataString.removeLast()
        guard let data = dataString.data(using: .utf8) else { return }
        request.httpBody = data
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let response = response as? HTTPURLResponse,
                  error == nil else {
                niprint("error", error ?? "Unknown error")
                onFailure(error ?? NSError(message: "Unknown"))
                return
            }
            
            let responseDict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            niprint(responseDict as Any)
            
            guard (200 ... 299) ~= response.statusCode else {
                niprint("statusCode: ", response.statusCode)
                onFailure(error ?? NSError(domain: "unknown", code: response.statusCode, userInfo: nil))
                return
            }
            
            if response.statusCode >= 200 && response.statusCode < 299 {
                onSuccess("success")
                return
            }
            
            guard let responseObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
                niprint("Can't decode")
                onFailure(NSError(message: "Can't decode"))
                return
            }
            onSuccess(responseObject)
        }
        
        task.resume()
    }
    
    public static func setUserId(_ userId: String) {
        NeuroID.userId = userId
        log(NIEvent(session: .setUserId, tg: ["userId": userId], x: nil, y: nil))
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
        log(NIEvent(customEvent: category, tg: ["content": content], x: nil, y: nil))
    }
    
    static func log(_ event: NIEvent) {
        guard let base64 = event.toBase64() else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            DB.shared.insert(screen: event.type, base64String: base64)
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
    
    init(screen: String, controller: UIViewController?) {
        super.init()
        self.screen = screen
        createSession(screen: screen)
        subscribe(inScreen: controller)
        className = controller?.className
    }
    
    public func log(event: NIEvent) {
        niprint(event.toDict())
        guard let base64 = event.toBase64() else { return }
        let screenName = screen ?? UUID().uuidString
        DB.shared.insert(screen: screenName, base64String: base64)
    }
}

// MARK: - Custom events
public extension NeuroIDTracker {
    func logCheckBoxChange(isChecked: Bool, checkBox: UIView) {
        var tg: [String: Any?] = ["isChecked": isChecked]
        let event = NIEvent(type: .checkboxChange,
                            tg: tg,
                            x: Int(checkBox.frame.origin.x),
                            y: Int(checkBox.frame.origin.y))
        log(event: event)
        
        tg["inputEvent"] = event.type
        log(event: NIEvent(type: .input, tg: tg,
                           x: Int(checkBox.frame.origin.x),
                           y: Int(checkBox.frame.origin.y)))
    }
    
    func logRadioChange(isChecked: Bool, radioButton: UIView) {
        log(event: NIEvent(type: .radioChange,
                           tg: ["isChecked": isChecked],
                           x: Int(radioButton.frame.origin.x),
                           y: Int(radioButton.frame.origin.y)))
    }
    
    func logSubmission(_ params: [String: Any?]? = nil) {
        log(event: NIEvent(type: .formSubmit, tg: params, x: nil, y: nil))
        log(event: NIEvent(type: .applicationSubmit, tg: params, x: nil, y: nil))
        log(event: NIEvent(type: .pageSubmit, tg: params, x: nil, y: nil))
    }
    
    func logSubmissionSuccess(_ params: [String: Any?]? = nil) {
        log(event: NIEvent(type: .formSubmitSuccess, tg: params, x: nil, y: nil))
        log(event: NIEvent(type: .applicationSubmitSuccess, tg: params, x: nil, y: nil))
    }
    
    func logSubmissionFailure(error: Error, params: [String: Any?]? = nil) {
        var newParams = params ?? [:]
        newParams["error"] = error.localizedDescription
        log(event: NIEvent(type: .formSubmitFailure, tg: newParams, x: nil, y: nil))
        log(event: NIEvent(type: .applicationSubmitFailure, tg: newParams, x: nil, y: nil))
    }
    
    func excludeViews(views: UIView...) {
        for v in views {
            NeuroID.secrectViews.append(v)
        }
    }
}

// MARK: - Private functions
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
    
    func createSession(screen: String) {
        let event = NIEvent(session: .createSession, tg: nil, x: nil, y: nil)
        guard let base64 = [event.toDict()].toBase64() else { return }
        let params = [
            "key": NeuroID.clientKey,
            "id": ParamsCreator.createRequestId(),
            "siteId": nil,
            "sid": NeuroID.sessionId,
            "cid": NeuroID.clientId,
            "aid": nil,
            "did": 1623787353447.57899235,
            "uid": NeuroID.userId,
            "pid": ParamsCreator.getPageId(),
            "iid": nil,
            "url": screen,
            "jsv": "4.0.0-beta-0-gd71221c",
            "events": base64
        ] as [String: Any?]
        NeuroID.post(params: params, onSuccess: { _ in }, onFailure: { _ in })
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
        logTextEvent(from: notification, eventType: .textChange)
    }
    
    @objc func textEndEditing(notification: Notification) {
        logTextEvent(from: notification, eventType: .blur)
    }
    
    func logTextEvent(from notification: Notification, eventType: NIEventName) {
        if let textField = notification.object as? UITextField {
            // isSecureText
            if textField.textContentType == .password || textField.isSecureTextEntry { return }
            if #available(iOS 12.0, *) {
                if textField.textContentType == .newPassword { return }
            }
            
            log(event: NIEvent(type: eventType, tg: ["text": textField.text],
                               x: Int(textField.frame.origin.x), y: Int(textField.frame.origin.y)))
        } else if let textView = notification.object as? UITextView {
            if textView.textContentType == .password || textView.isSecureTextEntry { return }
            if #available(iOS 12.0, *) {
                if textView.textContentType == .newPassword { return }
            }
            
            log(event: NIEvent(type: eventType, tg: ["text": textView.text],
                               x: Int(textView.frame.origin.x), y: Int(textView.frame.origin.y)))
        }
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
    
    func touchEvent(sender: UIView, eventName: NIEventName) {
        if NeuroID.secrectViews.contains(sender) { return }
        let tg: [String: Any?] = ["sender": sender.className]
        log(event: NIEvent(type: eventName, tg: tg, x: Int(sender.frame.origin.x), y: Int(sender.frame.origin.y)))
    }
}

// MARK: - value events
private extension NeuroIDTracker {
    func observeValueChanged(_ sender: UIControl) {
        sender.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }
    
    @objc func valueChanged(sender: UIView) {
        var eventName = NIEventName.change
        var tg: [String: Any?] = ["sender": sender.className]
        
        if let control = sender as? UISwitch {
            eventName = .selectChange
            tg["oldValue"] = !control.isOn
            tg["newValue"] = control.isOn
        } else if let control = sender as? UISegmentedControl {
            eventName = .selectChange
            tg["value"] = control.titleForSegment(at: control.selectedSegmentIndex)
            tg["selectedIndex"] = control.selectedSegmentIndex
        } else if let control = sender as? UIStepper {
            eventName = .change
            tg["value"] = control.value
        } else if let control = sender as? UISlider {
            eventName = .sliderChange
            tg["value"] = control.value
        } else if let control = sender as? UIDatePicker {
            eventName = .inputChange
            tg["value"] = "\(control.date)"
        }
        
        log(event: NIEvent(type: eventName, tg: tg, x: Int(sender.frame.origin.x), y: Int(sender.frame.origin.y)))
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
        log(event: NIEvent(type: NIEventName.userInactive, tg: nil, x: nil, y: nil))
    }
}

// MARK: - Pasteboard events
private extension NeuroIDTracker {
    func observePasteboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(contentCopied), name: UIPasteboard.changedNotification, object: nil)
    }
    
    @objc func contentCopied() {
        log(event: NIEvent(type: NIEventName.copy, tg: ["content": UIPasteboard.general.string], x: nil, y: nil))
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
        
        log(event: NIEvent(type: NIEventName.windowOrientationChange, tg: ["orientation": orientation], x: nil, y: nil))
        log(event: NIEvent(type: NIEventName.deviceOrientation, tg: ["orientation": orientation], x: nil, y: nil))
    }
}

// MARK: - Properties - temporary public for testing
struct ParamsCreator {
    static func getDefaultSessionParams() -> [String: Any] {
        let params: [String: Any] = [
            "type": "CREATE_SESSION",
            "f": getClientKey(),
            "sid": createSessionId(),
            "cid": getClientId(),
            "loc": getLocale(),
            "ua": getUserAgent(),
            "tzo": getTimezone(),
            "lng": getLanguage(),
            "aid": "null", // temp
            "did": "null", // temp
            "siteId": "null", // temp
            // ce,
            // je,
            // ol,
            "p": "Apple",
            "sh": UIScreen.main.bounds.height,
            "sw": UIScreen.main.bounds.width,
            "cd": 32,
            "pd": 32,
            // jsl,
            // dnt,
            "tch": true,
            "url": "",
            "ns": "nid",
            "jsv": getSDKVersion()
        ]
        return params
    }
    
    static func getDefaultEventParams() -> [String: Any] {
        guard let userId = NeuroID.userId else {
            fatalError("UserId is not set")
        }
        
        let params: [String: Any] = [
            "key": getClientKey(),
            "id": createRequestId(),
            "sid": NeuroID.sessionId,
            "cid": NeuroID.clientId,
            "uid": userId,
            "pid": getPageId(),
            "iid": 1, // temp
            "url": 1, // temp
            "jsv": 1, // temp
            "aid": "null", // temp
            "did": "null", // temp
            "siteId": "null" // temp
            
        ]
        return params
    }
    
    static func getClientKey() -> String {
        guard let key = NeuroID.clientKey else {
            fatalError("clientKey is not set")
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
    
    static func createSessionId() -> String {
        var id = ""
        for _ in 0 ..< 16 {
            let digit = Int.random(in: 0..<10)
            id += "\(digit)"
        }
        return id
    }
    
    static func getClientId() -> String {
        let now = Int(Date().timeIntervalSince1970 * 1000)
        let random = Int(Double.random(in: 0..<1) * Double(Int32.max))
        return "\(now).\(random)"
    }
    
    static func getLocale() -> String {
        return Locale.current.identifier
    }
    
    static func getUserAgent() -> String {
        return "iOS " + UIDevice.current.systemVersion
    }
    
    static func getTimezone() -> String {
        let timezone = TimeZone.current.abbreviation() ?? "Unidentified"
        return timezone
    }
    
    static func getLanguage() -> String {
        let locale = Locale.current.languageCode
        return locale ?? Locale.current.identifier
    }
    
    static func getSDKVersion() -> String {
        return "v-ios-1.0.0"
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
    
    func log(event: NIEvent) {
        if ignoreLists.contains(className) { return }
        var tg: [String: Any?] = event.tg ?? [:]
        tg["className"] = className
        tg["title"] = title
        if let vc = self as? UIAlertController {
            tg["message"] = vc.message
            tg["actions"] = vc.actions.compactMap { $0.title }
        }
        
        if let eventName = NIEventName(rawValue: event.type) {
            let newEvent = NIEvent(type: eventName, tg: tg, x: event.x, y: event.y)
            tracker?.log(event: newEvent)
        } else {
            let newEvent = NIEvent(customEvent: event.type, tg: tg, x: event.x, y: event.y)
            tracker?.log(event: newEvent)
        }
    }
    
    func log(eventName: NIEventName, params: [String: Any?]? = nil) {
        let event = NIEvent(type: eventName, tg: params, x: nil, y: nil)
        log(event: event)
    }
    
    func logViewWillAppear(params: [String: Any?]) {
        log(eventName: .windowFocus, params: params)
    }
    
    func logViewDidLoad(params: [String: Any?]) {
        log(eventName: .windowLoad, params: params)
    }
    
    func logViewWillDisappear(params: [String: Any?]) {
        log(eventName: .windowBlur, params: params)
    }
}

private extension UIViewController {
    @objc static func startSwizzling() {
        let screen = UIViewController.self
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.viewWillAppear),
                  swizzledSelector: #selector(screen.neuroIdViewWillAppear))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.viewWillDisappear),
                  swizzledSelector: #selector(screen.neuroIdViewWillDisappear))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.viewDidLoad),
                  swizzledSelector: #selector(screen.neuroIdViewDidLoad))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.dismiss),
                  swizzledSelector: #selector(screen.neuroIdDismiss))
    }
    
    @objc func neuroIdViewWillAppear(animated: Bool) {
        self.neuroIdViewWillAppear(animated: animated)
        log(eventName: .windowFocus)
    }
    
    @objc func neuroIdViewWillDisappear(animated: Bool) {
        self.neuroIdViewWillDisappear(animated: animated)
        log(eventName: .windowBlur)
    }
    
    @objc func neuroIdViewDidLoad() {
        self.neuroIdViewDidLoad()
        log(eventName: .windowLoad)
    }
    
    @objc func neuroIdDismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        self.neuroIdDismiss(animated: flag, completion: completion)
        log(eventName: .windowUnload)
    }
}

extension UINavigationController {
    fileprivate static func swizzleNavigation() {
        let screen = UINavigationController.self
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.popViewController(animated:)),
                  swizzledSelector: #selector(screen.neuroIdPopViewController(animated:)))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.popToViewController(_:animated:)),
                  swizzledSelector: #selector(screen.neuroIdPopToViewController(_:animated:)))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.popToRootViewController),
                  swizzledSelector: #selector(screen.neuroIdPopToRootViewController))
    }
    
    @objc fileprivate func neuroIdPopViewController(animated: Bool) -> UIViewController? {
        log(eventName: .windowUnload)
        return self.neuroIdPopViewController(animated: animated)
    }
    
    @objc fileprivate func neuroIdPopToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        log(eventName: .windowUnload)
        return self.neuroIdPopToViewController(viewController, animated: animated)
    }
    
    @objc fileprivate func neuroIdPopToRootViewController(animated: Bool) -> [UIViewController]? {
        log(eventName: .windowUnload)
        return self.neuroIdPopToRootViewController(animated: animated)
    }
}

extension NSError {
    convenience init(message: String) {
        self.init(domain: message, code: 0, userInfo: nil)
    }
    
    fileprivate static func errorSwizzling(_ obj: NSError.Type,
                                           originalSelector: Selector,
                                           swizzledSelector: Selector) {
        let originalMethod = class_getInstanceMethod(obj, originalSelector)
        let swizzledMethod = class_getInstanceMethod(obj, swizzledSelector)
        
        if let originalMethod = originalMethod,
           let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
    
    fileprivate static func startSwizzling() {
        let obj = NSError.self
        errorSwizzling(obj,
                       originalSelector: #selector(obj.init(domain:code:userInfo:)),
                       swizzledSelector: #selector(obj.neuroIdInit(domain:code:userInfo:)))
    }
    
    @objc fileprivate func neuroIdInit(domain: String, code: Int, userInfo dict: [String: Any]? = nil) {
        let tg: [String: Any?] = [
            "domain": domain,
            "code": code,
            "userInfo": userInfo
        ]
        NeuroID.log(NIEvent(type: .error, tg: tg, x: nil, y: nil))
        self.neuroIdInit(domain: domain, code: code, userInfo: userInfo)
    }
}

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

func niprint(_ strings: Any...) {
    if NeuroID.logVisible {
        Swift.print(strings)
    }
}

private struct Log {
    static var subsystem: String {
        return Bundle.main.bundleIdentifier ?? UUID().uuidString
    }
    
    @available(iOS 10.0, *)
    static let table = OSLog(subsystem: subsystem, category: "table")
    @available(iOS 10.0, *)
    static let networking = OSLog(subsystem: subsystem, category: "networking")
    
    @available(iOS 10.0, *)
    static func log(category: String, contents: Any..., type: OSLogType) {
        let message = contents.map { "\($0)"}.joined(separator: " ")
        let osLog = OSLog(subsystem: subsystem, category: category)
        os_log("%@", log: osLog, type: type, message)
    }
}
