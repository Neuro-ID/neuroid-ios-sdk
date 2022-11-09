import Foundation
import UIKit
import os
import WebKit
import CommonCrypto
import Alamofire
import ObjectiveC

public struct NeuroID {
    
    fileprivate static var sequenceId = 1
    fileprivate static var clientKey: String?
    fileprivate static var siteId: String?
    fileprivate static let sessionId: String = ParamsCreator.getSessionID()
    public static var clientId: String?
    public static var userId: String?
    private static let SEND_INTERVAL: Double = 5
    fileprivate static var trackers = [String: NeuroIDTracker]()
    fileprivate static var secretViews = [UIView]()
    fileprivate static let showDebugLog = false
    fileprivate static var _currentScreenName: String?
    
    static var excludedViewsTestIDs = [String]()
    private static let lock = NSLock()
    
    private static var environment: String = "TEST"
    private static var currentScreenName: String? {
        get { lock.withCriticalSection { _currentScreenName } }
        set { lock.withCriticalSection { _currentScreenName = newValue } }
    }
    
    fileprivate static let localStorageNIDStopAll = "nid_stop_all"

    /// Turn on/off printing the SDK log to your console
    public static var logVisible = true
    public static var activeView: UIView?
    public static var collectorURLFromConfig:String?
    public static var isSDKStarted = false;
    public static var observingInputs = false;
    
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
        
        // Reset tab id on configure
        UserDefaults.standard.set(nil, forKey: "nid_tid")
        
        NeuroID.createSession()
    }
    
    // Allow for configuring of collector endpoint (useful for testing before MSA is signed)
    public static func configure(clientKey: String, collectorEndPoint: String) {
        collectorURLFromConfig = collectorEndPoint
        configure(clientKey: clientKey)
    }
    
    /**
     Public user facing getClientID function
     */
    public static func getClientID() -> String {
        return ParamsCreator.getClientId()
    }
    
    public static func setEnvironmentProduction(_ value: Bool) {
        if (value) {
            self.environment = "LIVE"
        } else {
            self.environment = "TEST"
        }
    }
    
    public static func setSiteId(siteId: String) {
        self.siteId = siteId
    }
    
    public static func getEnvironment() -> String {
        return environment
    }
    public static func stop(){
        UserDefaults.standard.set(true, forKey: localStorageNIDStopAll)
    }
    
    public static func excludeViewByTestID(excludedView: String) {
        print("Exclude view called - \(excludedView)")
        NeuroID.excludedViewsTestIDs.append(excludedView)
    }
    
    /**
     Set screen name. We ensure that this is a URL valid name by replacing non alphanumber chars with underscore
     */
    public static func setScreenName(screen: String) {
        if let urlEncode = screen.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            currentScreenName = urlEncode
        } else {
            logError(content: "Invalid Screenname for NeuroID. \(screen) can't be encode")
        }
    }
    
    public static func getScreenName() -> String? {
        if (!currentScreenName.isEmptyOrNil) {
            return "\(currentScreenName ?? "")"
        }
        return currentScreenName
    }
    
    public static func clearSession(){
        UserDefaults.standard.set(nil, forKey: "nid_sid")
        UserDefaults.standard.set(nil, forKey: "nid_cid")
    }
    
    public static func getSessionID() -> String? {
        return UserDefaults.standard.string(forKey: "nid_sid")
    }
    
    
    static func createSession() {
        // Since we are creating a new session, clear any existing session ID
        NeuroID.clearSession()
        // TODO, return session if already exists
        var event = NIDEvent(session: .createSession, f: ParamsCreator.getClientKey(), sid: ParamsCreator.getSessionID(), lsid: nil, cid: ParamsCreator.getClientId(), did: ParamsCreator.getDeviceId(), loc: ParamsCreator.getLocale(), ua: ParamsCreator.getUserAgent(), tzo: ParamsCreator.getTimezone(), lng: ParamsCreator.getLanguage(),p: ParamsCreator.getPlatform(), dnt: false, tch: ParamsCreator.getTouch(),          pageTag: NeuroID.getScreenName(), ns: ParamsCreator.getCommandQueueNamespace(), jsv: ParamsCreator.getSDKVersion())
        event.sh = UIScreen.main.bounds.height
        event.sw = UIScreen.main.bounds.width
        event.metadata = NIDMetadata()
        saveEventToLocalDataStore(event)
    }
    
    public static func closeSession() -> NIDEvent {
        var closeEvent = NIDEvent(type: NIDEventName.closeSession)
        closeEvent.ct = "SDK_EVENT"
        saveEventToLocalDataStore(closeEvent)
        NeuroID.stop()
        return closeEvent
    }
    
    // When start is called, enable swizzling, as well as dispatch queue to send to API
    public static func start(){
        NeuroID.isSDKStarted = true
        clearSession()
        UserDefaults.standard.set(false, forKey: localStorageNIDStopAll)
        swizzle()
        
        if ProcessInfo.processInfo.environment["debugJSON"] == "true" {
            let filemgr = FileManager.default
            let path = filemgr.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("nidJSONPOSTFormat.txt")
            print("DEBUG PATH \(path.absoluteString)");
        }
        
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
    
    /**
        Form Submit, Sccuess & Failure
     */
    public static func formSubmit() -> NIDEvent{
        let submitEvent = NIDEvent(type: NIDEventName.applicationSubmit)
        saveEventToLocalDataStore(submitEvent);
        return submitEvent;
    }
    
    public static func formSubmitFailure() -> NIDEvent{
        let submitEvent = NIDEvent(type: NIDEventName.applicationSubmitFailure)
        saveEventToLocalDataStore(submitEvent);
        return submitEvent
    }
    
    public static func formSubmitSuccess() -> NIDEvent{
        let submitEvent = NIDEvent(type: NIDEventName.applicationSubmitSuccess)
        saveEventToLocalDataStore(submitEvent);
        return submitEvent
    }
    
    /**
     Set a custom variable with a key and value.
        - Parameters:
            - key: The string value of the variable key
            - v: The string value of variable
        - Returns: An `NIDEvent` object of type `SET_VARIABLE`
     
     */
    public static func setCustomVariable(key: String, v: String) -> NIDEvent{
        var setCustomVariable = NIDEvent(type: NIDSessionEventName.setVariable, key: key, v: v )
        let myKeys: [String] = trackers.map{String($0.key) }
        // Set the screen to the last active view
        setCustomVariable.url = myKeys.last
        // If we don't have a valid URL, that means this was called before any views were tracked. Use "AppDelegate" as default
        if (setCustomVariable.url == nil || setCustomVariable.url!.isEmpty) {
            setCustomVariable.url = "AppDelegate"
        }
        saveEventToLocalDataStore(setCustomVariable);
        return setCustomVariable
    }
    
    public static func getCollectionEndpointURL() -> String {
        // Prod URL
//      return collectorURLFromConfig ?? "https://api.neuro-id.com/v3/c"
//      return "https://rc.api.usw2-prod1.nidops.net"
//      return "http://localhost:8080"
//      return "https://api.usw2-dev1.nidops.net";
//
//        #if DEBUG
//        return collectorURLFromConfig ?? "https://receiver.neuro-dev.com/c"
//        #elseif STAGING
//        return collectorURLFromConfig ?? "https://receiver.neuro-dev.com/c"
//        #elseif RELEASE
//        return  "https://api.neuro-id.com/v3/c"
//        #endif
        return "https://receiver.neuroid.cloud/c"
    }
    
    static func getClientKeyFromLocalStorage() -> String {
        let keyName = "nid_key";
        let defaults = UserDefaults.standard
        let key = defaults.string(forKey: keyName);
        return key ?? ""
    }
    
    private static func swizzle() {
        UIViewController.startSwizzling()
        UITextField.startSwizzling()
        UITextView.startSwizzling()
        UINavigationController.swizzleNavigation()
        
//        UIButton.startSwizzling()
    }
    private static func initTimer() {
        // Send up the first payload, and then setup a repeating timer
//        self.send()
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + SEND_INTERVAL) {
            self.send()
            self.initTimer()
        }
    }
    /**
     Publically exposed just for testing. This should not be any reason to call this directly.
     */
    public static func send() {
        DispatchQueue.global(qos: .utility).async {
            if (!NeuroID.isStopped()) {
                groupAndPOST()
            }
        }
    }
    
    /**
     Publically exposed just for testing. This should not be any reason to call this directly.
     */
    public static func groupAndPOST() {
        if (NeuroID.isStopped()){
            return
        }
        let dataStoreEvents = DataStore.getAllEvents()

        let backupCopy = dataStoreEvents
        // Clean event queue immediately after fetching
        DataStore.removeSentEvents()
        if dataStoreEvents.isEmpty {
            return
        }
        
        /** Just send all the evnets*/
        let cleanEvents = dataStoreEvents.map { (nidevent) -> NIDEvent in
            var newEvent = nidevent
            // Only send url on register target and create session.
            if (nidevent.type != NIDEventName.registerTarget.rawValue && nidevent.type != "CREATE_SESSION") {
                newEvent.url = nil
            }
            return newEvent
        }
        
        post(events: cleanEvents , screen: (self.getScreenName() ?? backupCopy[0].url) ?? "unnamed_screen", onSuccess: { _ in
            logInfo(category: "APICall", content: "Sending successfully")
                // send success -> delete
                
            }, onFailure: { error in
                logError(category: "APICall", content: String(describing: error))
            })
    }
    
    /// Direct send to API to create session
    /// Regularly send in loop
    fileprivate static func post(events: [NIDEvent],
                                 screen: String,
                                 onSuccess: @escaping(Any) -> Void,
                                 onFailure: @escaping
    (Error) -> Void) {
        guard let url = URL(string: NeuroID.getCollectionEndpointURL()) else {
            logError(content: "NeuroID base URL found")
            return
        }

        
        let tabId = ParamsCreator.getTabId()
        
        let randomString = UUID().uuidString
        let pageid = randomString.replacingOccurrences(of: "-", with: "").prefix(12)
        
        let neuroHTTPRequest = NeuroHTTPRequest.init(clientId: ParamsCreator.getClientId(), environment: NeuroID.getEnvironment(), sdkVersion: ParamsCreator.getSDKVersion(), pageTag: NeuroID.getScreenName() ?? "UNKNOWN", responseId: ParamsCreator.generateUniqueHexId(), siteId: NeuroID.siteId ?? "", userId: ParamsCreator.getUserID() ?? "", jsonEvents: events, tabId: "\(tabId)", pageId: "\(pageid)", url: "ios://\(NeuroID.getScreenName() ?? "")")

        if ProcessInfo.processInfo.environment["debugJSON"] == "true" {
            saveDebugJSON(events: "******************** New POST to NID Collector")
//            saveDebugJSON(events: dataString)
//            saveDebugJSON(events: jsonEvents):
            saveDebugJSON(events: "******************** END")
        }
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "site_key": ParamsCreator.getClientKey(),
            "authority": "receiver.neuroid.cloud"
        ]

        AF.request(url, method: .post, parameters: neuroHTTPRequest, encoder: JSONParameterEncoder.default, headers: headers).responseData { response in
                // 204 invalid, 200 valid
                NIDPrintLog("NID Response \(response.response?.statusCode)")
                switch response.result {
                case .success:
                    NIDPrintLog("Neuro-ID post to API Successfull")
                case let .failure(error):
                    NIDPrintLog("Neuro-ID FAIL to post API")
                    logError(content: "Neuro-ID post Error: \(error)")
                }
            }

        // Output post data to terminal if debug
        if ProcessInfo.processInfo.environment["debugJSON"] == "true" {
            do {
                let data = try JSONEncoder().encode(neuroHTTPRequest)
                let str = String(data: data, encoding: .utf8)
                print(str)
            } catch {}
        }
    }

    public static func setUserID(_ userId: String) {
        UserDefaults.standard.set(userId, forKey: "nid_user_id")
        let setUserEvent = NIDEvent(session: NIDSessionEventName.setUserId, userId: userId);
        NeuroID.userId = userId
        NIDPrintLog("NID userID = <\(userId)>")
        saveEventToLocalDataStore(setUserEvent)
    }
    
    public static func getUserID() -> String {
        var userId = UserDefaults.standard.string(forKey: "nid_user_id")
        return NeuroID.userId ?? userId ?? ""
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

    public static func saveEventToLocalDataStore(_ event: NIDEvent) {
            DataStore.insertEvent(screen: event.type, event: event)
    }
    
    /**
     Save the params being sent to POST to collector endpoint to a local file
     */
    private static func saveDebugJSON(events: String){
        let jsonStringNIDEvents = "\(events)".data(using: .utf8)!
        do {

            let filemgr = FileManager.default
            let path = filemgr.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("nidJSONPOSTFormat.txt")
            if !filemgr.fileExists(atPath: (path.path)) {
                filemgr.createFile(atPath: (path.path), contents: jsonStringNIDEvents, attributes: nil)
                
            } else {
                let file = FileHandle(forReadingAtPath: (path.path))
                if let fileUpdater = try? FileHandle(forUpdating: path) {
    
                    // Function which when called will cause all updates to start from end of the file
                    fileUpdater.seekToEndOfFile()

                    // Which lets the caller move editing to any position within the file by supplying an offset
                    fileUpdater.write(",\n".data(using: .utf8)!)
                    fileUpdater.write(jsonStringNIDEvents)
                }
                else {
                    print("Unable to append DEBUG JSON")
                }
            }
        } catch{
            print(String(describing: error))
        }
    }
}

extension NeuroID {
    static func cleanUpForTesting() {
        clientKey = nil
    }
    /// Get the current SDK versión from bundle
    /// - Returns: String with the version format
    public static func getSDKVersion() -> String? {
        return  ParamsCreator.getSDKVersion()
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
        if (!NeuroID.isStopped()){
            subscribe(inScreen: controller)
        }
        className = controller?.className
    }

    
    public func captureEvent(event: NIDEvent) {
        if (NeuroID.isStopped()){
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
    
    public static func getFullViewlURLPath(currView: UIView?, screenName: String) -> String{
        if (currView == nil) {
            return screenName
        }
        let parentView = currView!.superview?.className
        let grandParentView = currView!.superview?.superview?.className
        var fullViewString = ""
        if (grandParentView != nil){
            fullViewString += "\(grandParentView ?? "")/"
            fullViewString += "\(parentView ?? "")/"
        } else if (parentView != nil) {
            fullViewString = "\(parentView ?? "")/"
        }
        fullViewString += screenName
        return fullViewString
    }
    
    // function which is triggered when handleTap is called
    @objc static func neuroTextTouchListener() {
         print("Hello World")
      }
    
    public static func registerSingleView(v: Any, screenName: String, guid: String){
        
        let screenName = NeuroID.getScreenName() ?? screenName
        let currView = v as? UIView

        NIDPrintLog("Registering view: \(screenName)")
        let fullViewString = NeuroIDTracker.getFullViewlURLPath(currView: currView, screenName: screenName)
        switch v {
//        case is UIView:
//            let tfView = v as! UIView
//
//            let touchListener = UITapGestureRecognizer(target: tfView, action: #selector(self.neuroTextTouchListener(_:)))
//            tfView.addGestureRecognizer(touchListener)
        case is UITextField:
            let tfView = v as! UITextField
                             
//                             @objc func myTargetFunction(textField: UITextField) {     print("myTargetFunction") }

//            // Add view on top of textfield to get taps
//            var invisView = UIView.init(frame: tfView.frame)
////            invisView.backgroundColor = UIColor(red: 100.0, green: 0.0, blue: 0.0, alpha: 0.0)
//
//            invisView.backgroundColor = UIColor(red: 0.8, green: 0.1, blue: 0.5, alpha: 1)
//            tfView.addSubview(invisView)
//            let tap = UITapGestureRecognizer(target: self , action: #selector(self.handleTap(_:)))
//            invisView.addGestureRecognizer(tap)
//            invisView.superview?.bringSubviewToFront(invisView)
//            invisView.superview?.layer.zPosition = 10000000
            
            var temp = getParentClasses(currView: currView, hierarchyString: "UITextField")
            var nidEvent = NIDEvent(eventName: NIDEventName.registerTarget, tgs: tfView.id, en: tfView.id, etn: "INPUT", et: "UITextField::\(tfView.className)", ec: screenName, v: "S~C~~\(tfView.placeholder?.count ?? 0)" , url: screenName)
            nidEvent.hv = tfView.placeholder?.sha256().prefix(8).string
            var attrVal = Attrs.init(n: "guid", v: guid)
            // Screen hierarchy
            var shVal = Attrs.init(n: "screenHierarchy", v: fullViewString)
            var guidValue = Attr.init(n: "guid", v: guid)
            var attrValue = Attr.init(n: "screenHierarchy", v: fullViewString)
            nidEvent.tg = ["attr": TargetValue.attr([attrValue, guidValue])]
            nidEvent.attrs = [attrVal,shVal]
            NeuroID.saveEventToLocalDataStore(nidEvent)
        case is UITextView:
            let tv = v as! UITextView

            var temp = getParentClasses(currView: currView, hierarchyString: "UITextView")

            var nidEvent = NIDEvent(eventName: NIDEventName.registerTarget, tgs: tv.id, en: tv.id, etn: "INPUT", et: "UITextView::\(tv.className)", ec: screenName, v: "S~C~~\(tv.text?.count ?? 0)" , url: screenName)
            nidEvent.hv = tv.text?.sha256().prefix(8).string
            var attrVal = Attrs.init(n: "guid", v: guid)
            // Screen hierarchy
            var shVal = Attrs.init(n: "screenHierarchy", v: fullViewString)
            var guidValue = Attr.init(n: "guid", v: guid)
            var attrValue = Attr.init(n: "screenHierarchy", v: fullViewString)
            nidEvent.tg = ["attr": TargetValue.attr([attrValue, guidValue])]
            nidEvent.attrs = [attrVal,shVal]
            NeuroID.saveEventToLocalDataStore(nidEvent)
        case is UIButton:
            let tb = v as! UIButton
            var nidEvent = NIDEvent(eventName: NIDEventName.registerTarget, tgs: tb.id, en: tb.id, etn: "BUTTON", et: "UIButton::\(tb.className)", ec: screenName, v: "S~C~~\(tb.titleLabel?.text?.count ?? 0)" , url: screenName)
            nidEvent.hv = tb.titleLabel?.text?.sha256().prefix(8).string
            var attrVal = Attrs.init(n: "guid", v: guid)
            // Screen hierarchy
            var shVal = Attrs.init(n: "screenHierarchy", v: fullViewString)
            nidEvent.attrs = [attrVal,shVal]
            
            var guidValue = Attr.init(n: "guid", v: guid)
            var attrValue = Attr.init(n: "screenHierarchy", v: fullViewString)
            nidEvent.tg = ["attr": TargetValue.attr([attrValue, guidValue])]
            NeuroID.saveEventToLocalDataStore(nidEvent)
        case is UISlider:
            print("Slider")
        case is UISwitch:
            print("Switch")
        case is UITableViewCell:
            print("Table view cell")
            break
        case is UIPickerView:
            let pv = v as! UIPickerView
            print("Picker")
        case is UIDatePicker:
            print("Date picker")
        default:
            return
    //        print("Unknown type", v)
        }
            // Text
            // Inputs
            // Checkbox/Radios inputs
    }
}

// MARK: - Custom events
public extension NeuroIDTracker {
    func captureEventCheckBoxChange(isChecked: Bool, checkBox: UIView) {
        let tg = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.checkboxChange, view: checkBox, type: "UIView", attrParams: nil)
        let event = NIDEvent(type: .checkboxChange, tg: tg, v: String(isChecked))
        captureEvent(event: event)
    }

    func captureEventRadioChange(isChecked: Bool, radioButton: UIView) {
        let tg = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.radioChange, view: radioButton, type: "UIView", attrParams: nil)
        captureEvent(event: NIDEvent(type: .radioChange, tg: tg, v: String(isChecked)))
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
            NeuroID.secretViews.append(v)
        }
    }

}

// MARK: - Private functions


extension Bundle {
    static func infoPlistValue(forKey key: String) -> Any? {

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
        // Early exit if we are stopped
        if (NeuroID.isStopped()){
            return;
        }
        if let views = controller?.view.subviews {
            observeViews(views)
        }
        
        // Only run observations on first run
        if (!NeuroID.observingInputs) {
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
        // Set the current value of the textDictionary
        // Used for similarity and diff
        
        DispatchQueue.global(qos:.utility).async { [self] in
            if let textControl = notification.object as? UITextField {
                // Touch event start
                // TODO, this begin editing could eventually be an invisible view over the input item to be a true tap...
                self.touchEvent(sender: textControl, eventName: .touchStart)
                UserDefaults.standard.setValue(textControl.text, forKey: textControl.id)
            } else if let textControl = notification.object as? UITextView {
                // Touch event start
                self.touchEvent(sender: textControl, eventName: .touchStart)
                UserDefaults.standard.setValue(textControl.text, forKey: textControl.id)
            }

        }
        logTextEvent(from: notification, eventType: .focus)
    }
    
    
    @objc func textChange(notification: Notification) {
        
        DispatchQueue.global(qos:.utility).async {
            var similarity:Double = 0;
            var percentDiff:Double = 0;
            if let textControl = notification.object as? UITextField {
                
                // TODO Paste detection
//                if (UIPasteboard.general.string == textControl.text) {
//
//                }
                let existingTextValue = UserDefaults.standard.value(forKey: textControl.id)
                UserDefaults.standard.setValue(textControl.text, forKey: textControl.id)
                 similarity = self.calcSimilarity(previousValue: existingTextValue as? String ?? "", currentValue: textControl.text ?? "")
                 percentDiff = self.percentageDifference(newNumOrig: textControl.text ?? "", originalNumOrig: existingTextValue as? String ?? "")
            } else if let textControl = notification.object as? UITextView {
                let existingTextValue = UserDefaults.standard.value(forKey: textControl.id)
                // TODO Finish Paste detection
//                if (UIPasteboard.general.string == textControl.text) {
//
//                }
                UserDefaults.standard.setValue(textControl.text, forKey: textControl.id)
                 similarity = self.calcSimilarity(previousValue: existingTextValue as? String ?? "", currentValue: textControl.text ?? "")
                 percentDiff = self.percentageDifference(newNumOrig: textControl.text ?? "", originalNumOrig: existingTextValue as? String ?? "")
            }
            self.logTextEvent(from: notification, eventType: .input, sm: similarity, pd: percentDiff)
        }
        // count the number of letters in 10ms (for instance) -> consider paste action
    }

    @objc func textEndEditing(notification: Notification) {
        /**
         We want to make sure to erase user defaults on blur for security
         */
        DispatchQueue.global(qos:.utility).async {
            if let textControl = notification.object as? UITextField {
                UserDefaults.standard.setValue("", forKey: textControl.id)
            } else if let textControl = notification.object as? UITextView {
                UserDefaults.standard.setValue("", forKey: textControl.id)
            }
        }
        logTextEvent(from: notification, eventType: .blur)
    }

    /**
     Target values:
        ETN - Input
        ET - human readable tag
     */
    func logTextEvent(from notification: Notification, eventType: NIDEventName, sm: Double = 0, pd: Double = 0) {
        
        if let textControl = notification.object as? UITextField {
            let inputType = "text"
            // isSecureText
            if #available(iOS 11.0, *) {
                if textControl.textContentType == .password || textControl.isSecureTextEntry { return }
            }
            if #available(iOS 12.0, *) {
                if textControl.textContentType == .newPassword { return }
            }
            
            let lengthValue = "S~C~~\(textControl.text?.count ?? 0)"
            let hashValue = textControl.text?.sha256().prefix(8).string
            if (eventType == NIDEventName.input) {
                NIDPrintLog("NID keydown field = <\(textControl.id)>")
//                // Keydown
//                let keydownTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.keyDown, view: textControl, type: inputType)
//                var keyDownEvent = NIDEvent(type: NIDEventName.keyDown, tg: keydownTG)
//                keyDownEvent.v = lengthValue
//                captureEvent(event: keyDownEvent)
                
                // Input
                let inputTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.input, view: textControl, type: inputType, attrParams: ["v": lengthValue, "hash": textControl.text])
                var inputEvent = NIDEvent(type: NIDEventName.input, tg: inputTG)
//                inputEvent.v = lengthValue
                inputEvent.v = lengthValue
                inputEvent.hv = hashValue
                inputEvent.tgs = TargetValue.string(textControl.id).toString()
                captureEvent(event: inputEvent)
            } else if (eventType == NIDEventName.focus || eventType == NIDEventName.blur) {
                // Focus / Blur
                var focusBlurEvent = NIDEvent(type: eventType, tg: [
                    "tgs": TargetValue.string(textControl.id),
                ])
                focusBlurEvent.tgs = TargetValue.string(textControl.id).toString()
                captureEvent(event: focusBlurEvent)
                
                // If this is a blur event, that means we have a text change event
                if (eventType == NIDEventName.blur) {
                    // Text Change
                    let textChangeTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.textChange, view: textControl, type: inputType, attrParams: ["v": lengthValue, "hash": textControl.text])
                    var textChangeEvent = NIDEvent(type:NIDEventName.textChange, tg: textChangeTG, sm: sm, pd: pd)
                    textChangeEvent.v = lengthValue
                    var shaText = textControl.text ?? ""
                    if (shaText != "") {
                     shaText = shaText.sha256().prefix(8).string
                    }
                    textChangeEvent.hv = shaText
                    textChangeEvent.tgs = TargetValue.string(textControl.id).toString()
//                    textChangeEvent.hv = hashValue
                    captureEvent(event:  textChangeEvent)
                    NeuroID.send()
                }
            }
            
//            detectPasting(view: textControl, text: textControl.text ?? "")
        } else if let textControl = notification.object as? UITextView {
            let inputType = "text"
            // isSecureText
            if #available(iOS 11.0, *) {
                if textControl.textContentType == .password || textControl.isSecureTextEntry { return }
            }
            if #available(iOS 12.0, *) {
                if textControl.textContentType == .newPassword { return }
            }
            
            let hashValue = textControl.text?.sha256().prefix(8).string
            let lengthValue = "S~C~~\(textControl.text?.count ?? 0)"
            if (eventType == NIDEventName.input) {
                NIDPrintLog("NID keydown field = <\(textControl.id)>")
                
                // Keydown
                let keydownTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.keyDown, view: textControl, type: inputType, attrParams: ["v": lengthValue, "hash": textControl.text])
                var keyDownEvent = NIDEvent(type: NIDEventName.keyDown, tg: keydownTG)
                keyDownEvent.v = lengthValue
                keyDownEvent.tgs = TargetValue.string(textControl.id).toString()
//                keyDownEvent.hv = hashValue
                captureEvent(event: keyDownEvent)
                
                // Text Change
                let textChangeTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.textChange, view: textControl, type: inputType, attrParams: nil)
                var textChangeEvent = NIDEvent(type:NIDEventName.textChange, tg: textChangeTG, sm: sm, pd: pd)
                textChangeEvent.v = lengthValue
                textChangeEvent.hv = hashValue
                textChangeEvent.tgs = TargetValue.string(textControl.id).toString()
                captureEvent(event:  textChangeEvent)
                
                // Input
                let inputTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.input, view: textControl, type: inputType, attrParams: nil)
                var inputEvent = NIDEvent(type: NIDEventName.input, tg: inputTG)
                inputEvent.v = lengthValue
                inputEvent.hv = hashValue
                inputEvent.tgs = TargetValue.string(textControl.id).toString()
                captureEvent(event: inputEvent)
            } else if (eventType == NIDEventName.focus || eventType == NIDEventName.blur) {
                // Focus / Blur
                var focusBlurEvent = NIDEvent(type: eventType, tg: [
                    "tgs": TargetValue.string(textControl.id),
                ])
                focusBlurEvent.tgs = TargetValue.string(textControl.id).toString()
                captureEvent(event: focusBlurEvent)
                
                // If this is a blur event, that means we have a text change event
                if (eventType == NIDEventName.blur) {
                    // Text Change
                    let textChangeTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.textChange, view: textControl, type: inputType, attrParams: nil)
                    var textChangeEvent = NIDEvent(type:NIDEventName.textChange, tg: textChangeTG, sm: sm, pd: pd)
                    textChangeEvent.v = lengthValue
                    textChangeEvent.tgs = TargetValue.string(textControl.id).toString()
//                    textChangeEvent.hv = hashValue
                    captureEvent(event:  textChangeEvent)
                }
            }
            
//            detectPasting(view: textControl, text: textControl.text ?? "")
        } else if let textControl = notification.object as? UISearchBar {
            let tg = ParamsCreator.getTGParamsForInput(eventName: eventType, view: textControl, type: "UISearchBar", attrParams: nil)
            var searchEvent = NIDEvent(type: eventType, tg: tg)
            searchEvent.tgs = TargetValue.string(textControl.id).toString()
            captureEvent(event: searchEvent)
//            detectPasting(view: textControl, text: textControl.text ?? "")
        }

    }

//    func detectPasting(view: UIView, text: String) {
//        var id = "\(Unmanaged.passUnretained(view).toOpaque())"
//        guard var savedText = textCapturing[id] else {
//           return
//        }
//        let savedCount = savedText.count
//        let newCount = text.count
//        if newCount > 0 && newCount - savedCount > 2 {
//            let tg = ParamsCreator.getTextTgParams(
//                view: view,
//                extraParams: ["etn": TargetValue.string(NIDEventName.input.rawValue)])
//            captureEvent(event: NIDEvent(type: .paste, tg: tg, view: view))
//        }
//        textCapturing[id] = text
//    }
    
    public func calcSimilarity(previousValue: String, currentValue: String) -> Double {
      var longer = previousValue;
      var shorter = currentValue;

      if (previousValue.count < currentValue.count) {
        longer = currentValue;
        shorter = previousValue;
      }
      let longerLength = Double(longer.count);

      if (longerLength == 0) {
        return 1;
      }

        return round(((longerLength - Double(levDis(longer, shorter))) / longerLength) * 100) / 100.0;
    }
    
    func levDis(_ w1: String, _ w2: String) -> Int {
        let empty = [Int](repeating:0, count: w2.count)
        var last = [Int](0...w2.count)

        for (i, char1) in w1.enumerated() {
            var cur = [i + 1] + empty
            for (j, char2) in w2.enumerated() {
                cur[j + 1] = char1 == char2 ? last[j] : min(last[j], last[j + 1], cur[j]) + 1
            }
            last = cur
        }
        return last.last!
    }
    
    public func percentageDifference(newNumOrig: String, originalNumOrig: String) -> Double{
      let originalNum = originalNumOrig.replacingOccurrences(of: " ", with: "")
        let newNum = newNumOrig.replacingOccurrences(of: " ", with: "")
   
        guard var originalNumParsed = Double (originalNum) else {
            return -1
        }
        
        guard var newNumParsed = Double (newNum) else {
            return -1
        }

      if (originalNumParsed <= 0) {
          originalNumParsed = 1;
      }

      if (newNumParsed <= 0) {
          newNumParsed = 1;
      }

        return round(Double((newNumParsed - originalNumParsed) / originalNumParsed) * 100) / 100.0;
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
        NeuroID.activeView = sender
        touchEvent(sender: sender, eventName: .touchStart)
    }

    @objc func controlTouchEnd(sender: UIView) {
        touchEvent(sender: sender, eventName: .touchEnd)
    }

    @objc func controlTouchMove(sender: UIView) {
        touchEvent(sender: sender, eventName: .touchMove)
    }

    func touchEvent(sender: UIView, eventName: NIDEventName) {
        if NeuroID.secretViews.contains(sender) { return }
        let tg = ParamsCreator.getTgParams(
            view: sender,
            extraParams: ["sender": TargetValue.string(sender.className)])

        captureEvent(event: NIDEvent(type: eventName, tg: tg, view: sender))
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
            
            NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIScene.willEnterForegroundNotification, object: nil)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        }
    }

    @objc func appMovedToBackground() {
        captureEvent(event: NIDEvent(type: NIDEventName.windowBlur))
    }
   
    @objc func appMovedToForeground() {
        captureEvent(event: NIDEvent(type: NIDEventName.windowFocus))
    }
}

//// MARK: - Pasteboard events
//private extension NeuroIDTracker {
//    func observePasteboard() {
//        NotificationCenter.default.addObserver(self, selector: #selector(contentCopied), name: UIPasteboard.changedNotification, object: nil)
//    }
//
//    @objc func contentCopied(notification: Notification) {
//        captureEvent(event: NIDEvent(type: NIDEventName.copy, tg: ParamsCreator.getCopyTgParams(), view: NeuroID.activeView))
//    }
//}

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

//        captureEvent(event: NIDEvent(type: NIDEventName.windowOrientationChange, tg: ["orientation": TargetValue.string(orientation)], view: nil))
//        captureEvent(event: NIDEvent(type: NIDEventName.deviceOrientation, tg: ["orientation": TargetValue.string(orientation)], view: nil))
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
    
    static func getTGParamsForInput(eventName: NIDEventName, view: UIView, type: String, extraParams: [String: TargetValue] = [:], attrParams: [String: Any]?) -> [String: TargetValue] {
        var params: [String: TargetValue] = [:];
        
        switch eventName {
        case NIDEventName.focus, NIDEventName.blur, NIDEventName.textChange, NIDEventName.radioChange, NIDEventName.checkboxChange, NIDEventName.input, NIDEventName.copy, NIDEventName.paste, NIDEventName.click:
            
//            var attrParams:Attr;
            var inputValue = attrParams?["v"] as? String ?? "S~C~~"
            var attrVal = Attr.init(n: "v", v: inputValue)

            var textValue = attrParams?["hash"] as? String ?? ""
            var hashValue = Attr.init(n: "hash", v: textValue.sha256().prefix(8).string)
            var attrArraryVal:[Attr] = [attrVal, hashValue]
            params = [
                "tgs": TargetValue.string(view.id),
                "etn": TargetValue.string(view.id),
                "et": TargetValue.string(type),
                "attr": TargetValue.attr(attrArraryVal)
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
        let sidName =  "nid_sid"
        let sidExpires = "nid_sid_expires"
        let defaults = UserDefaults.standard
        let sid = defaults.string(forKey: sidName)
        
        // TODO Expire sesions
        if (sid != nil) {
            return sid ?? "";
        }

        var id = UUID().uuidString
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
        if (NeuroID.clientId != nil)
        {
            cid = NeuroID.clientId
        }
        // Ensure we aren't on old client id
        if (cid != nil && !cid!.contains("_")){
            return cid!;
        } else {
            cid = genId()
            NeuroID.clientId = cid
            UserDefaults.standard.set(cid, forKey: clientIdName)
            return cid!
        }
    }
    
    static func getTabId() -> String {
        let tabIdName = "nid_tid";
        var tid = UserDefaults.standard.string(forKey: tabIdName);
        
        if (tid != nil && !tid!.contains("-")){
            return tid!;
        } else {
            let randString = UUID().uuidString
            let tid = randString.replacingOccurrences(of: "-", with: "").prefix(12)
            UserDefaults.standard.set(tid, forKey: tabIdName)
            return "\(tid)"
        }
    }
    
    static func getUserID() -> String? {
        let nidUserID = "nid_user_id";
        return UserDefaults.standard.string(forKey: nidUserID);
    }
    
    static func getDeviceId() -> String {
        let deviceIdCacheKey = "nid_did";
        var did = UserDefaults.standard.string(forKey: deviceIdCacheKey);
        
        if (did != nil && did!.contains("_")){
            return did!;
        } else {
            did = self.genId()
            UserDefaults.standard.set(did, forKey: deviceIdCacheKey)
            return did!
        }
    }
    
    private static func genId() -> String {
        return UUID().uuidString;
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
        // Version MUST start with 4. in order to be processed correctly
        let version = Bundle(for: NeuroIDTracker.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return "5.ios-\(version ?? "?")"
    }
    static func getCommandQueueNamespace() -> String {
        return "nid";
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

extension UIView {

    func subviewsRecursive() -> [Any] {
        return subviews + subviews.flatMap { $0.subviewsRecursive() }
    }

}


private func getParentClasses(currView: UIView?, hierarchyString: String?) -> String? {
    
    var newHieraString = "\(currView?.className ?? "UIView")"
    
    if (hierarchyString != nil) {
        newHieraString = "\(newHieraString)\\\(hierarchyString!)"
    }

    if (currView?.superview != nil){
        getParentClasses(currView: currView?.superview, hierarchyString: newHieraString)
    }
   return newHieraString
}

private func registerSubViewsTargets(subViewControllers: [UIViewController]){
    for ctrls in subViewControllers {
        let screenName = ctrls.className
        NIDPrintLog("Registering view controllers \(screenName)")
        guard let view = ctrls.view else {
            return
        }
        let guid = UUID().uuidString
        
        NeuroIDTracker.registerSingleView(v: view, screenName: screenName, guid: guid)
        let childViews = ctrls.view.subviewsRecursive()
        for _view in childViews {
            NIDPrintLog("Registering single view.")
            NeuroIDTracker.registerSingleView(v: _view, screenName: screenName, guid: guid)
        }
    }
}

private func uiButtonSwizzling(element: UIButton.Type,
                       originalSelector: Selector,
                       swizzledSelector: Selector) {

    let originalMethod = class_getInstanceMethod(element, originalSelector)
    let swizzledMethod = class_getInstanceMethod(element, swizzledSelector)

    if let originalMethod = originalMethod,
       let swizzledMethod = swizzledMethod {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

private func textViewSwizzling(element: UITextView.Type,
                       originalSelector: Selector,
                       swizzledSelector: Selector) {

    let originalMethod = class_getInstanceMethod(element, originalSelector)
    let swizzledMethod = class_getInstanceMethod(element, swizzledSelector)

    if let originalMethod = originalMethod,
       let swizzledMethod = swizzledMethod {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}


private func textFieldSwizzling(element: UITextField.Type,
                       originalSelector: Selector,
                       swizzledSelector: Selector) {

    let originalMethod = class_getInstanceMethod(element, originalSelector)
    let swizzledMethod = class_getInstanceMethod(element, swizzledSelector)

    if let originalMethod = originalMethod,
       let swizzledMethod = swizzledMethod {
        method_exchangeImplementations(originalMethod, swizzledMethod)
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
//            "UIInputWindowController",
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
        let event:NIDEvent;
        if (params.isEmptyOrNil) {
            event = NIDEvent(type: eventName, view: self.view)
        } else {
            event = NIDEvent(type: eventName, tg: params, view: self.view)
        }
        captureEvent(event: event)
    }

//    public func captureEventLogViewWillAppear(params: [String: TargetValue]) {
//        captureEvent(eventName: .windowFocus, params: params)
//    }
//
//    public func captureEventLogViewDidLoad(params: [String: TargetValue]) {
//        captureEvent(eventName: .windowLoad, params: params)
//    }
//
//    public func captureEventLogViewWillDisappear(params: [String: TargetValue]) {
//        captureEvent(eventName: .windowBlur, params: params)
//    }
}

//private extension UIButton {
//    @objc static func startSwizzling() {
//        let uiButton = UIButton.self
//
//        uiButtonSwizzling(element: uiButton,
//                          originalSelector: #selector(uiButton.touchesBegan(_:with:)),
//                  swizzledSelector: #selector(uiButton.nidButtonPress))
//    }
//
//    @objc func nidButtonPress(_ touches: Set<UITouch>, with event: UIEvent?) {
//
//
//        self.nidButtonPress(touches, with: event)
////        if (self.responds(to: #selector(touchesBegan))) {
////            self.nidButtonPress(touches, with: event)
////        }
////
//        if (NeuroID.isStopped()){
//            return
//        }
//        if (self.responds(to: #selector(getter: titleLabel))) {
//            let lengthValue = "S~C~~\(self.titleLabel?.text?.count ?? 0)"
//            let clickTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.click, view: self, type: NIDEventName.click.rawValue, attrParams: ["v": lengthValue, "hash": self.titleLabel?.text])
//            var clickEvent = NIDEvent(type: NIDEventName.click, tg: clickTG)
//
//            let screenName = self.className ?? UUID().uuidString
//            var newEvent = clickEvent
//            // Make sure we have a valid url set
//            newEvent.url = screenName
//            DataStore.insertEvent(screen: screenName, event: newEvent)
//            NeuroID.logDebug(category: "saveEvent", content: "save event finish")
//        }
////        super.touchesBegan(touches, with: event)
//    }
//}

private extension UIView {
    // Add tap recognizer to all views?
    
//    func test(view: UIView){

//    }
//    @objc static func startSwizzling() {
//        test(self.viewWithTag(self))
////        UIView.self.addGestureRecognizer(touchListener)
//    }
//
//    convenience private override init() {
//        print("hi")
//    }

    
}

private extension UITextField {
//    func  addTapGesture(){
//        let tap = UITapGestureRecognizer(target: self , action: #selector(self.handleTap(_:)))
//        self.addGestureRecognizer(tap)
//
//    }
//    @objc func handleTap(_ sender: UITapGestureRecognizer) {
//        print("Gesture recognized")
//    }

    @objc static func startSwizzling() {
        let textField = UITextField.self

        textFieldSwizzling(element: textField,
                           originalSelector: #selector(textField.paste(_:)),
                  swizzledSelector: #selector(textField.neuroIDPaste))

    }
    
   
    @objc func neuroIDPaste(caller: UIResponder) {
        if (NeuroID.isStopped()){
            return
        }
        let lengthValue = "S~C~~\(self.text?.count ?? 0)"
        let pasteTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.paste, view: self, type: NIDEventName.paste.rawValue, attrParams: ["v": lengthValue, "hash": self.text])
        var inputEvent = NIDEvent(type: NIDEventName.paste, tg: pasteTG)
        
        let screenName = self.className ?? UUID().uuidString
        var newEvent = inputEvent
        // Make sure we have a valid url set
        newEvent.url = screenName
        DataStore.insertEvent(screen: screenName, event: newEvent)
        self.neuroIDPaste(caller: caller)
    }
}

private extension UITextView {
    
    func  addTapGesture(){
        let tap = UITapGestureRecognizer(target: self , action: #selector(self.handleTap(_:)))
        self.addGestureRecognizer(tap)
        self.isUserInteractionEnabled = true

    }
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        print("wow")
        
    }
    
    @objc static func startSwizzling() {
        let textField = UITextView.self
        
        textViewSwizzling(element: textField,
                           originalSelector: #selector(textField.paste(_:)),
                  swizzledSelector: #selector(textField.neuroIDPaste))
        
    }
    
    @objc func neuroIDPaste(caller: UIResponder) {
        if (NeuroID.isStopped()){
            return
        }
        let lengthValue = "S~C~~\(self.text?.count ?? 0)"
        let pasteTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.paste, view: self, type: NIDEventName.paste.rawValue, attrParams: ["v": lengthValue, "hash": self.text])
        var inputEvent = NIDEvent(type: NIDEventName.paste, tg: pasteTG)
        
        let screenName = self.className ?? UUID().uuidString
        var newEvent = inputEvent
        // Make sure we have a valid url set
        newEvent.url = screenName
        DataStore.insertEvent(screen: screenName, event: newEvent)
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
                  originalSelector: #selector(screen.viewDidAppear),
                  swizzledSelector: #selector(screen.neuroIDViewDidAppear))
        swizzling(viewController: screen,
                  originalSelector: #selector(screen.dismiss),
                  swizzledSelector: #selector(screen.neuroIDDismiss))
    }
    
    @objc func neuroIDViewWillAppear(animated: Bool) {
        self.neuroIDViewWillAppear(animated: animated)
    }

    @objc func neuroIDViewWillDisappear(animated: Bool) {
        self.neuroIDViewWillDisappear(animated: animated)
        NotificationCenter.default.removeObserver(self)
//        captureEvent(eventName: .windowBlur)
    }

    /**
        When overriding viewDidLoad in  controllers make sure that super is the last thing called in the function (so that we can accurately detect all added views/subviews)
    
          Anytime a view loads
          Check child subviews for eligible form events
          Form all eligible form events, check to see if they have a valid identifier and set one
          Register form events
     */
    @objc func neuroIDViewDidAppear() {
        self.neuroIDViewDidAppear()
        
        if (NeuroID.isStopped()){
            return
        }
        // We need to init the tracker on the views.
        tracker
//        captureEvent(eventName: .windowFocus)
        var subViews = self.view.subviews
        var allViewControllers = self.children
        allViewControllers.append(self)
        registerSubViewsTargets(subViewControllers: allViewControllers)
    }

    @objc func neuroIDDismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        self.neuroIDDismiss(animated: flag, completion: completion)
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
    if (NeuroID.isStopped()){
        return
    }
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
            var title = "UNKNOWN_NO_ID_SET"
            
            if #available(iOS 13.0, *) {
                title = "UNKNOWN_NO_ID_SET"
                title.replacingOccurrences(of: " ", with: "_")
            } else {
                // Fallback on earlier versions
            }
            title = "\(self.className)_\(title)"
            var backupName = ("\(self.className)\(self.description.hashValue)")
            return (accessibilityIdentifier.isEmptyOrNil) ? title : (accessibilityIdentifier!)
        }
        set {
            accessibilityIdentifier = newValue
        }
    }
}


extension Dictionary {
  func toKeyValueString() -> String {
    return map { key, value in
      let escapedKey = "\(key)" ?? ""
      let escapedValue = "\(value)" ?? ""
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


extension Data{
    public func sha256() -> String{
        return hexStringFromData(input: digest(input: self as NSData))
    }
    
    private func digest(input : NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }
    
    private  func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)
        
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }
        
        return hexString
    }
}

public extension String {
    func sha256() -> String{
        var saltedString = self + UUID().uuidString
        if let stringData = saltedString.data(using: String.Encoding.utf8) {
            return stringData.sha256()
        }
        return ""
    }    
}


