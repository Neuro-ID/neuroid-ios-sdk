import UIKit

internal enum NIDSessionEventName: String {
    case createSession = "CREATE_SESSION"
    case closeSession = "CLOSE_SESSION"
    case stateChange = "STATE_CHANGE"
    case setUserId = "SET_USER_ID"
    case setVariable = "SET_VARIABLE"
    case tag = "TAG"
    case setCheckPoint = "SET_CHECKPOINT"
    case setCustomEvent = "SET_CUSTOM_EVENT"
    case heartBeat = "HEARTBEAT"

    func log() {
        let event = NIDEvent(session: self, tg: nil, x: nil, y: nil)
        NeuroID.saveEventToLocalDataStore(event)
    }
}

public enum NIDEventName: String {
    case createSession = "CREATE_SESSION"
    case closeSession = "CLOSE_SESSION"
    case heartbeat = "HEARTBEAT"
    case error = "ERROR"
    case log = "LOG"
    case userInactive = "USER_INACTIVE"
    case registerComponent = "REGISTER_COMPONENT"
    case registerTarget = "REGISTER_TARGET"
    case registerStylesheet = "REGISTER_STYLESHEET"
    case mutationInsert = "MUTATION_INSERT"
    case mutationRemove = "MUTATION_REMOVE"
    case mutationAttr = "MUTATION_ATTR"
    case formSubmit = "FORM_SUBMIT"
    case formReset = "FORM_RESET"
    case formSubmitSuccess = "FORM_SUBMIT_SUCCESS"
    case formSubmitFailure = "FORM_SUBMIT_FAILURE"
    case applicationSubmit = "APPLICATION_SUBMIT"
    case applicationSubmitSuccess = "APPLICATION_SUBMIT_SUCCESS"
    case applicationSubmitFailure = "APPLICATION_SUBMIT_FAILURE"
    case pageSubmit = "PAGE_SUBMIT"
    case focus = "FOCUS"
    case blur = "BLUR"
    case copy = "COPY"
    case click = "CLICK"
    case cut = "CUT"
    case paste = "PASTE"
    case input = "INPUT"
    case invalid = "INVALID"
    case keyDown = "KEY_DOWN"
    case keyUp = "KEY_UP"
    case change = "CHANGE"
    case selectChange = "SELECT_CHANGE"
    case textChange = "TEXT_CHANGE"
    case radioChange = "RADIO_CHANGE"
    case checkboxChange = "CHECKBOX_CHANGE"
    case inputChange = "INPUT_CHANGE"
    case sliderChange = "SLIDER_CHANGE"
    case sliderSetMin = "SLIDER_SET_MIN"
    case sliderSetMax = "SLIDER_SET_MAX"
    case touchStart = "TOUCH_START"
    case touchMove = "TOUCH_MOVE"
    case touchEnd = "TOUCH_END"
    case touchCancel = "TOUCH_CANCEL"
    case windowLoad = "WINDOW_LOAD"
    case windowUnload = "WINDOW_UNLOAD"
    case windowFocus = "WINDOW_FOCUS"
    case windowBlur = "WINDOW_BLUR"
    case windowOrientationChange = "WINDOW_ORIENTATION_CHANGE"
    case windowResize = "WINDOW_RESIZE"
    case deviceMotion = "DEVICE_MOTION"
    case deviceOrientation = "DEVICE_ORIENTATION"
    
    var etn: String? {
        switch self {
        case .change, .textChange, .radioChange, .inputChange,
             .paste, .keyDown, .keyUp, .selectChange, .sliderChange:
            return rawValue
        default:
            return nil
        }
    }
}

public struct Attrs: Codable, Equatable {
    var n: String?
    var v: String?
}

public struct Attr: Codable, Equatable {
    var guid: String?
    var screenHierarchy: String?
    var n: String?
    var v: String?
    var hash: String?
}

public struct NIDTouches: Codable, Equatable {
    var x: CGFloat?
    var y: CGFloat?
    var tid: Int?
}

public struct NeuroHTTPRequest: Codable {
    var clientId: String
    var environment: String
    var sdkVersion: String
    var pageTag: String
    var responseId: String
    var siteId: String
    var userId: String
    var jsonEvents: [NIDEvent]
    var tabId: String
    var pageId: String
    var url: String
    var jsVersion: String = "5.0.0"
    
    public init(clientId: String, environment: String, sdkVersion: String, pageTag: String,
                responseId: String, siteId: String, userId: String, jsonEvents: [NIDEvent],
                tabId: String, pageId: String, url: String)
    {
        self.clientId = clientId
        self.environment = environment
        self.sdkVersion = sdkVersion
        self.pageTag = pageTag
        self.responseId = responseId
        self.siteId = siteId
        self.userId = userId
        self.jsonEvents = jsonEvents
        self.tabId = tabId
        self.pageId = pageId
        self.url = url
    }
}

public enum TargetValue: Codable, Equatable {
    case int(Int), string(String), bool(Bool), double(Double), attrs([Attrs]), attr([Attr])

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .int(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .attrs(let value): try container.encode(value)
        case .attr(let value): try container.encode(value)
        }
    }
    
    public func toString() -> String {
        switch self {
        case .int(let int):
            return String(int)
        case .string(let string):
            return string
        case .bool(let bool):
            return String(bool)
        case .double(let double):
            return String(double)
        case .attr(let array):
            return String(describing: array)
        case .attrs(let array):
            return String(describing: array)
        }
    }
    
    public init(from decoder: Decoder) throws {
        if let int = try? decoder.singleValueContainer().decode(Int.self) {
            self = .int(int)
            return
        }
        
        if let double = try? decoder.singleValueContainer().decode(Double.self) {
            self = .double(double)
            return
        }
        
        if let string = try? decoder.singleValueContainer().decode(String.self) {
            self = .string(string)
            return
        }
        
        if let bool = try? decoder.singleValueContainer().decode(Bool.self) {
            self = .bool(bool)
            return
        }
        
        if let attrs = try? decoder.singleValueContainer().decode(Attrs.self) {
            self = .attrs([attrs])
            return
        }
        if let attr = try? decoder.singleValueContainer().decode(Attr.self) {
            self = .attr([attr])
            return
        }
        
        throw TG.missingValue
    }
    
    enum TG: Error {
        case missingValue
    }
}

public struct EventCache: Codable {
    var nidEvents: [NIDEvent]
}

public struct NIDEvent: Codable {
    public let type: String
    var tg: [String: TargetValue]? = nil
    var tgs: String?
    var key: String?
    var ct: String?
    var v: String?
    var hv: String?
    var en: String?
    var etn: String? // Tag name (input)
    var et: String? // Element Type (text)
    var ec: String? // This is the currentl "URL" (or View) we are on
    var eid: String?
    var ts: Int64 = ParamsCreator.getTimeStamp()
    var x: CGFloat?
    var y: CGFloat?
    var f: String?
    var lsid: String?
    var sid: String? // Done
    var cid: String? // Done
    var did: String? // Done
    var loc: String? // Done
    var ua: String? // Done
    var tzo: Int? // Done
    var lng: String? // Done
    var p: String? // Done
    var dnt: Bool? // Done
    var tch: Bool? // Done
    var url: String?
    var ns: String? // Done
    var jsl: [String]? //  = ["iOS"];
    var jsv: String? // Done
    var uid: String?
    var sm: Double?
    var pd: Double?
    var attrs: [Attrs]?
    var gyro: NIDSensorData?
    var accel: NIDSensorData?
    var touches: [NIDTouches]?
    var metadata: NIDMetadata?
    var sh: CGFloat?
    var sw: CGFloat?

    /**
        Use to initiate a new session
         Element mapping:
         
         type: CREATE_SESSION,
         f: key,
         siteId: siteId,
         sid: sessionId,
         lsid: lastSessionId,
         clientId: clientId,
         did: deviceId,
         loc: locale,
         ua: userAgent,
         tzo: timezoneOffset,
         lng: language,
         ce: cookieEnabled,
         je: javaEnabled,
         ol: onLine,
         p: platform,
         sh: screenHeight,
         sw: screenWidth,
         ah: availHeight,
         aw: availWidth,
         cd: colorDepth,
         pd: pixelDepth,
         jsl: jsLibraries,
         dnt: doNotTrack,
         tch: touch,
         pageTag: pageTag,
         ns: commandQueueNamespace,
        sdkVersion: sdkVersion,
         is: idleSince,
         ts: Date.now(),
     
        Event Change
        type: CHANGE,
       tg: { tgs: target, et: eventMetadata.elementType, etn: eventMetadata.elementTagName },
       v: eventMetadata.value,
       sm: eventMetadata.similarity,
       pd: eventMetadata.percentDiff,
       pl: eventMetadata.previousLength,
       cl: eventMetadata.currentLength,
       ld: eventMetadata.levenshtein,
       ts: Date.now(),
     */
        
//    public init(from decoder: Decoder) throws {
//        //
//    }
    init(session: NIDSessionEventName,
         f: String? = nil,
         sid: String? = nil,
         lsid: String? = nil,
         cid: String? = nil,
         did: String? = nil,
         loc: String? = nil,
         ua: String? = nil,
         tzo: Int? = nil,
         lng: String? = nil,
         p: String? = nil,
         dnt: Bool? = nil,
         tch: Bool? = nil,
         pageTag: String? = nil,
         ns: String? = nil,
         jsv: String? = nil,
         gyro: NIDSensorData? = nil,
         accel: NIDSensorData? = nil)
    {
        self.type = session.rawValue
        self.f = f
        self.sid = sid
        self.lsid = lsid
        self.cid = cid
        self.did = did
        self.loc = loc
        self.ua = ua
        self.tzo = tzo
        self.lng = lng
        self.p = p
        self.dnt = dnt
        self.tch = tch
        self.url = pageTag
        self.ns = ns
        self.jsv = jsv
        self.jsl = []
        self.gyro = gyro
        self.accel = accel
    }
    
    /** Register Target
       {"type":"REGISTER_TARGET","tgs":"#happyforms_message_nonce","en":"happyforms_message_nonce","eid":"happyforms_message_nonce","ec":"","etn":"INPUT","et":"hidden","ef":null,"v":"S~C~~10","ts":1633972363470}
         ET - Submit, Blank, Hidden
     
     */

    init(type: NIDEventName) {
        self.type = type.rawValue
    }
    
    init(eventName: NIDEventName, tgs: String, en: String, etn: String, et: String, ec: String, v: String, url: String) {
        self.type = eventName.rawValue
        self.tgs = tgs
        self.en = en
        self.eid = tgs
        self.ec = ec
        self.etn = etn
        self.et = et
        var ef: Any = String?.none
        self.v = v
        self.url = url
    }
    
    /**
        Text Change
     */
    init(type: NIDEventName, tg: [String: TargetValue]?, sm: Double, pd: Double) {
        self.type = type.rawValue
        self.tg = tg
        self.sm = sm
        self.pd = pd
    }

    /**
     Primary View Controller will be the URL that we are tracking.
     */
    public init(type: NIDEventName, tg: [String: TargetValue]?, primaryViewController: UIViewController?, view: UIView?) {
        self.type = type.rawValue
        var newTg = tg ?? [String: TargetValue]()
        newTg["tgs"] = TargetValue.string(view != nil ? view!.id : "")
        self.tg = newTg
        self.tgs = TargetValue.string(view != nil ? view!.id : "").toString()
        self.url = primaryViewController?.className
        self.x = view?.frame.origin.x
        self.y = view?.frame.origin.y
    }
    
    init(session: NIDSessionEventName, tg: [String: TargetValue]?, x: CGFloat?, y: CGFloat?) {
        self.type = session.rawValue
        self.tg = tg
        self.x = x
        self.y = y
    }
    
    /**
     * Form submit, Sucess Submit, Failure Submit
     */
    init(typeName: NIDEventName) {
        self.type = typeName.rawValue
    }
    
    init(type: NIDEventName, tg: [String: TargetValue]?, v: String) {
        self.type = type.rawValue
        self.tg = tg
        self.v = v
    }
    
    /**
     Set custom variable
        - Parameters:
            - type: NIDEventName
            - key: String value of key
            - v: String value of the value
        - Returns: An NIDEvent instance
     */
    init(type: NIDSessionEventName, key: String, v: String) {
        self.type = type.rawValue
        self.key = key
        self.v = v
    }
    
    /**
     Set UserID Event
     */
    init(session: NIDSessionEventName, userId: String) {
        self.uid = userId
        self.type = session.rawValue
    }
    
    init(type: NIDEventName, tg: [String: TargetValue]?, x: CGFloat?, y: CGFloat?) {
        self.type = type.rawValue
        self.tg = tg
        self.x = x
        self.y = y
    }

    init(customEvent: String, tg: [String: TargetValue]?, x: CGFloat?, y: CGFloat?) {
        self.type = customEvent
        self.tg = tg
        self.x = x
        self.y = y
    }
    
    /**
     FOCUS
     BLUR
     LOAD
     */
    
    public init(type: NIDEventName, view: UIView) {
        self.url = NeuroIDTracker.getFullViewlURLPath(currView: view, screenName: NeuroID.getScreenName() ?? view.className ?? "")
        self.type = type.rawValue
        self.ts = ParamsCreator.getTimeStamp()
    }
    
    public init(type: NIDEventName, tg: [String: TargetValue]?) {
        self.type = type.rawValue
        self.tg = tg
    }

    public init(type: NIDEventName, tg: [String: TargetValue]?, view: UIView?) {
        self.type = type.rawValue
        self.tgs = TargetValue.string(view != nil ? view!.id : "").toString()
        var newTg = tg ?? [String: TargetValue]()
        newTg["tgs"] = TargetValue.string(view != nil ? view!.id : "")
        self.ts = ParamsCreator.getTimeStamp()
        self.tg = newTg
        self.url = NeuroIDTracker.getFullViewlURLPath(currView: view, screenName: NeuroID.getScreenName() ?? view?.className ?? "")
        self.ts = ParamsCreator.getTimeStamp()
        switch type {
        case .touchStart, .touchMove, .touchEnd, .touchCancel:
            let touch = NIDTouches(x: view?.frame.origin.x, y: view?.frame.origin.y, tid: Int.random(in: 0 ... 10000))
            self.touches = []
            self.touches?.append(touch)
        default:
            self.x = view?.frame.origin.x
            self.y = view?.frame.origin.y
        }
    }
    
    var asDictionary: [String: Any] {
        let mirror = Mirror(reflecting: self)
        let dict = Dictionary(uniqueKeysWithValues: mirror.children.lazy.map { (label: String?, value: Any) -> (String, Any)? in
            guard let label = label else { return nil }
            return (label, value)
        }.compactMap { $0 })
        return dict
    }
    
    func toDict() -> [String: Any?] {
        let valuesAsDict = self.asDictionary
        return valuesAsDict
    }
}

extension Collection where Iterator.Element == [String: Any?] {
    func toJSONString() -> String {
        if let arr = self as? [[String: Any?]],
           let dat = try? JSONSerialization.data(withJSONObject: arr),
           let str = String(data: dat, encoding: String.Encoding.utf8)
        {
            return str
        }
        return "[]"
    }
}

extension Collection where Iterator.Element == NIDEvent {
    func toArrayOfDicts() -> [[String: Any?]] {
        let dat = self.map { $0.asDictionary.mapValues { value in
            value
        } }

        return dat
    }
}
