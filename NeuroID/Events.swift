import UIKit

internal enum NIDSessionEventName: String {
    case createSession = "CREATE_SESSION"
    case stateChange = "STATE_CHANGE"
    case setUserId = "SET_USER_ID"
    case setVariable = "SET_VARIABLE"
    case tag = "TAG"
    case setCheckPoint = "SET_CHECKPOINT"
    case setCustomEvent = "SET_CUSTOM_EVENT"
    case heartBeat = "HEARTBEAT"

    func log() {
        let event = NIDEvent(session: self, tg: nil, x: nil, y: nil)
        NeuroID.captureEvent(event)
    }
}

public enum NIDEventName: String {
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
        case .change, .textChange, .radioChange, .inputChange, .paste, .keyDown, .keyUp, .selectChange, .sliderChange:
            return rawValue
        default:
            return nil
        }
    }
}

public struct NIDEvent {
    public let type: String
    var tg: [String: Any?]? = nil
    var ts = ParamsCreator.getTimeStamp()
    var x: CGFloat?
    var y: CGFloat?
    var f: String?
    var lsid: String?
    var sid: String? // Done
    var siteId: String? // Unused
    var cid: String? // Done
    var did: String? // Done
    var iid: String? // Done
    var loc: String? // Done
    var ua: String? // Done
    var tzo: Int?  // Done
    var lng: String? // Done
    var p: String? // Done
    var dnt: Bool? // Done
    var tch: Bool? // Done
    var url: String?
    var ns: String? // Done
    var jsl: Array<String>  = ["iOS"];
    var jsv: String? // Done

        /**
            Use to initiate a new session
             Element mapping:
         
             type: CREATE_SESSION,
             f: key,
             siteId: siteId,
             sid: sessionId,
             lsid: lastSessionId,
             cid: clientId,
             did: deviceId,
             iid: intermediateId,
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
             url: url,
             ns: commandQueueNamespace,
             jsv: jsVersion,
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
    
    
        init(session: NIDSessionEventName,
             f: String? = nil,
             siteId: String? = nil,
             sid: String? = nil,
             lsid: String? = nil,
             cid: String? = nil,
             did: String? = nil,
             iid: String? = nil,
             loc: String? = nil,
             ua: String? = nil,
             tzo: Int? = nil,
             lng: String? = nil,
             p: String? = nil,
             dnt: Bool? = nil,
             tch: Bool? = nil,
             url: String? = nil,
             ns: String? = nil,
             jsv: String? = nil) {
            
            self.type = session.rawValue
            self.f = f
            self.siteId = siteId
            self.sid = sid
            self.lsid = lsid
            self.cid = cid
            self.did = did
            self.iid = iid
            self.loc = loc
            self.ua = ua
            self.tzo = tzo
            self.lng = lng
            self.p = p
            self.dnt = dnt
            self.tch = tch
            self.url = url
            self.ns = ns
            self.jsv = jsv
            
        }
    
    var asDictionary : [String:Any] {
        let mirror = Mirror(reflecting: self)
        let dict = Dictionary(uniqueKeysWithValues: mirror.children.lazy.map({ (label:String?, value:Any) -> (String, Any)? in
          guard let label = label else { return nil }
          return (label, value)
        }).compactMap { $0 })
        return dict
      }
    
    init(session: NIDSessionEventName, tg: [String: Any?]?, x: CGFloat?, y: CGFloat?) {
        type = session.rawValue
        self.tg = tg
        self.x = x
        self.y = y
    }

    init(type: NIDEventName, tg: [String: Any?]?, x: CGFloat?, y: CGFloat?) {
        self.type = type.rawValue
        self.tg = tg
        self.x = x
        self.y = y
    }

    init(customEvent: String, tg: [String: Any?]?, x: CGFloat?, y: CGFloat?) {
        self.type = customEvent
        self.tg = tg
        self.x = x
        self.y = y
    }

    public init(type: NIDEventName, tg: [String: Any?]?, view: UIView?) {
        self.type = type.rawValue
        var newTg = tg ?? [String: Any?]()
        newTg["tgs"] = view?.id
        self.tg = newTg
        self.x = view?.frame.origin.x
        self.y = view?.frame.origin.y
    }

    public init(customEvent: String, tg: [String: Any?]?, view: UIView?) {
        type = customEvent
        var newTg = tg ?? [String: Any?]()
        newTg["tgs"] = view?.id
        self.tg = newTg
        self.x = view?.frame.origin.x
        self.y = view?.frame.origin.y
    }

    func toDict() -> [String: Any] {
        let valuesAsDict = self.asDictionary;
        return valuesAsDict
    }

    func toBase64() -> String? {
        let dict = toDict()

        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: .fragmentsAllowed)
            let base64 = data.base64EncodedString()
            return base64
        } catch let error {
            niprint("Encode event", dict, "to base64 failed with error", error)
            return nil
        }
    }
}

extension Array {
    func toBase64() -> String? {
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: .fragmentsAllowed)
            let base64 = data.base64EncodedString()
            return base64
        } catch let error {
            niprint("Encode event", self, "to base64 failed with error", error)
            return nil
        }
    }
}
