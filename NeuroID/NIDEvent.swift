import UIKit

enum NIDSessionEventName: String {
    case createSession = "CREATE_SESSION"
    case closeSession = "CLOSE_SESSION"
    case stateChange = "STATE_CHANGE"
    case setUserId = "SET_USER_ID"
    case setRegisteredUserId = "SET_REGISTERED_USER_ID"
    case setVariable = "SET_VARIABLE"
    case tag = "TAG"
    case setCheckPoint = "SET_CHECKPOINT"
    case setCustomEvent = "SET_CUSTOM_EVENT"
    case heartBeat = "HEARTBEAT"
    case setLinkedSite = "SET_LINKED_SITE"

    case mobileMetadataIOS = "MOBILE_METADATA_IOS"
    case configCached = "CONFIG_CACHED"
}

public enum NIDEventName: String {
    case createSession = "CREATE_SESSION"
    case closeSession = "CLOSE_SESSION"
    case attemptedLogin = "ATTEMPTED_LOGIN"
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
    case stepperChange = "STEPPER_CHANGE"
    case colorWellChange = "COLOR_WELL_CHANGE"
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

    case customTouchStart = "CUSTOM_TOUCH_START"
    case customTouchEnd = "CUSTOM_TOUCH_END"
    case customDoubleTap = "CUSTOM_DOUBLE_TAP"
    case customTap = "CUSTOM_TAP"
    case customLongPress = "CUSTOM_LONG_PRESS"
    case doubleClick = "DB_CLICK"
    case navControllerPush = "NAV_CONTROLLER_PUSH"
    case navControllerPop = "NAV_CONTROLLER_POP"

    case mobileMetadataIOS = "MOBILE_METADATA_IOS"

    case advancedDevice = "ADVANCED_DEVICE_REQUEST"

    case callInProgress = "CALL_IN_PROGRESS"

    case cadenceReadingAccel = "CADENCE_READING_ACCEL"
    case networkState = "NETWORK_STATE"
    case applicationMetaData = "APPLICATION_METADATA"
    case advancedDeviceRequestFailed = "ADVANCED_DEVICE_REQUEST_FAILED"

    // Memory and queue events
    case bufferFull = "FULL_BUFFER"
    case lowMemory = "LOW_MEMORY"

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

    var force: CGFloat?
    var majorRadius: CGFloat?
    var phase: Int?
    var majorRadiusTolerance: CGFloat?
    var tapCount: Int?
    var type: Int?
    var preciseLocation: CGPoint?

    func toAttrs() -> [Attrs] {
        return [
            Attrs(n: "x", v: "\(self.x ?? 0)"),
            Attrs(n: "y", v: "\(self.y ?? 0)"),
            Attrs(n: "tid", v: "\(self.tid ?? 0)"),

            Attrs(n: "force", v: "\(self.force ?? 0)"),
            Attrs(n: "majorRadius", v: "\(self.majorRadius ?? 0)"),
            Attrs(n: "phase", v: "\(self.phase ?? -1)"),
            Attrs(n: "majorRadiusTolerance", v: "\(self.majorRadiusTolerance ?? 0)"),
            Attrs(n: "tapCount", v: "\(self.tapCount ?? 0)"),
            Attrs(n: "type", v: "\(self.type ?? -1)"),
            Attrs(n: "preciseLocationX", v: "\(self.preciseLocation?.x ?? 0)"),
            Attrs(n: "preciseLocationY", v: "\(self.preciseLocation?.y ?? 0)"),
        ]
    }
}

public struct NeuroHTTPRequest: Codable {
    var clientId: String
    var environment: String
    var sdkVersion: String
    var pageTag: String
    var responseId: String
    var siteId: String
    var userId: String? // this is the only reference where userId stays but really means sessionID in the context of mobile sdk
    var registeredUserId: String?
    var jsonEvents: [NIDEvent]
    var tabId: String
    var pageId: String
    var url: String
    var jsVersion: String = "5.0.0"
    var linkedSiteId: String?
    var packetNumber: Int32

    public init(
        clientID: String,
        environment: String,
        sdkVersion: String,
        pageTag: String,
        responseID: String,
        siteID: String,
        linkedSiteID: String?,
        sessionID: String?,
        registeredUserID: String?,
        jsonEvents: [NIDEvent],
        tabID: String,
        pageID: String,
        url: String,
        packetNumber: Int32
    ) {
        self.clientId = clientID
        self.environment = environment
        self.sdkVersion = sdkVersion
        self.pageTag = pageTag
        self.responseId = responseID
        self.siteId = siteID
        self.linkedSiteId = linkedSiteID
        self.userId = sessionID
        self.registeredUserId = registeredUserID
        self.jsonEvents = jsonEvents
        self.tabId = tabID
        self.pageId = pageID
        self.url = url
        self.packetNumber = packetNumber
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

    public func toArrayString() -> String {
        switch self {
        case .attr(let array):
            return array.map { value in
                "attr(guid=\(value.guid ?? ""), screenHierarchy=\(value.screenHierarchy ?? ""), n=\(value.n ?? ""), v=\(value.v ?? ""), hash=\(value.hash ?? ""))"
            }.joined(separator: ",  ")
        case .attrs(let array):
            return array.map { value in
                "n=\(value.n ?? ""), v=\(value.v ?? "")"
            }.joined(separator: ", ")
        default:
            return ""
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

public class NIDEvent: Codable {
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
    var h: CGFloat?
    var w: CGFloat?
    var f: String?
    var l: Double? // Latency (advanced device request)
    var lsid: String?
    var sid: String? // Done
    var cid: String? // Done
    var did: String? // Done
    var rid: String?
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
    var rts: String?
    var c: Bool?
    var cp: String? // call in progress status
    var m: String? // part of LOG events
    var level: String? // part of LOG events

    var iswifi: Bool?
    var isconnected: Bool?

    // Generic Event Init instead of one off inits
    init(
        type: NIDEventName,
        tg: [String: TargetValue]? = nil,
        tgs: String? = nil,
        key: String? = nil,
        ct: String? = nil,
        v: String? = nil,
        hv: String? = nil,
        en: String? = nil,
        etn: String? = nil,
        et: String? = nil,
        ec: String? = nil,
        eid: String? = nil,
        x: CGFloat? = nil,
        y: CGFloat? = nil,
        h: CGFloat? = nil,
        w: CGFloat? = nil,
        f: String? = nil,
        l: Double? = nil,
        lsid: String? = nil,
        sid: String? = nil,
        cid: String? = nil,
        did: String? = nil,
        rid: String? = nil,
        loc: String? = nil,
        ua: String? = nil,
        tzo: Int? = nil,
        lng: String? = nil,
        p: String? = nil,
        dnt: Bool? = nil,
        tch: Bool? = nil,
        url: String? = nil,
        ns: String? = nil,
        jsl: [String]? = nil,
        jsv: String? = nil,
        uid: String? = nil,
        sm: Double? = nil,
        pd: Double? = nil,
        attrs: [Attrs]? = nil,
        gyro: NIDSensorData? = nil,
        accel: NIDSensorData? = nil,
        touches: [NIDTouches]? = nil,
        metadata: NIDMetadata? = nil,
        sh: CGFloat? = nil,
        sw: CGFloat? = nil,
        rts: String? = nil,
        c: Bool? = nil,
        cp: String? = nil,
        m: String? = nil,
        level: String? = nil,
        iswifi: Bool? = nil,
        isconnected: Bool? = nil
    ) {
        self.type = type.rawValue
        self.tg = tg
        self.tgs = tgs
        self.key = key
        self.ct = ct
        self.v = v
        self.hv = hv
        self.en = en
        self.etn = etn
        self.et = et
        self.ec = ec
        self.eid = eid
        self.x = x
        self.y = y
        self.h = h
        self.w = w
        self.f = f
        self.l = l
        self.lsid = lsid
        self.sid = sid
        self.cid = cid
        self.did = did
        self.rid = rid
        self.loc = loc
        self.ua = ua
        self.tzo = tzo
        self.lng = lng
        self.p = p
        self.dnt = dnt
        self.tch = tch
        self.url = url
        self.ns = ns
        self.jsl = jsl
        self.jsv = jsv
        self.uid = uid
        self.sm = sm
        self.pd = pd
        self.attrs = attrs
        self.gyro = gyro
        self.accel = accel
        self.touches = touches
        self.metadata = metadata
        self.sh = sh
        self.sw = sw
        self.rts = rts
        self.c = c
        self.cp = cp
        self.m = m
        self.level = level
        self.iswifi = iswifi
        self.isconnected = isconnected
    }

    /** Register Target
       {"type":"REGISTER_TARGET","tgs":"#happyforms_message_nonce","en":"happyforms_message_nonce","eid":"happyforms_message_nonce","ec":"","etn":"INPUT","et":"hidden","ef":null,"v":"S~C~~10","ts":1633972363470}
         ET - Submit, Blank, Hidden
     */

    init(type: NIDEventName) {
        self.type = type.rawValue
    }

    init(sessionEvent: NIDSessionEventName) {
        self.type = sessionEvent.rawValue
    }

    init(rawType: String) {
        self.type = rawType
    }
    
    init(rawEventType: String, uid:String? = nil) {
        self.type = rawEventType
        self.uid = uid
    }

    init(type: NIDEventName = NIDEventName.log, level: String, m: String) {
        self.type = type.rawValue
        self.level = level
        self.m = m
    }

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

    init(
        session: NIDSessionEventName,
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
        accel: NIDSensorData? = nil,
        rts: String? = nil,
        sh: CGFloat? = nil,
        sw: CGFloat? = nil,
        metadata: NIDMetadata? = nil,
        cp: String? = nil
    ) {
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
        self.rts = rts
        self.sh = sh
        self.sw = sw
        self.metadata = metadata
        self.cp = cp
    }

    /**
     SET_TARGET
     */

    init(sessionEvent: NIDSessionEventName, key: String, v: String) {
        self.type = sessionEvent.rawValue
        self.key = key
        self.v = v
    }

    /**
     FOCUS
     BLUR
     LOAD
     */

    public init(type: NIDEventName, tg: [String: TargetValue]?) {
        self.type = type.rawValue
        self.tg = tg
    }

    /**
     Attempted login
     */
    public init(uid: String?) {
        self.type = NIDEventName.attemptedLogin.rawValue
        self.uid = uid
    }

    public init(type: NIDEventName, tg: [String: TargetValue]?, view: UIView?) {
        let viewId = TargetValue.string(view != nil ? view!.id : "")

        var newTg = tg ?? [String: TargetValue]()
        newTg["\(Constants.tgsKey.rawValue)"] = viewId

        self.type = type.rawValue
        self.ts = ParamsCreator.getTimeStamp()
        self.url = view != nil ? UtilFunctions.getFullViewlURLPath(
            currView: view!
        ) : NeuroID.getScreenName() ?? view?.nidClassName ?? ""

        self.tgs = viewId.toString()
        self.tg = newTg

        switch type {
        case .touchStart, .touchMove, .touchEnd, .touchCancel:
            let touch = NIDTouches(
                x: view?.frame.origin.x,
                y: view?.frame.origin.y,
                tid: -1
            )
            self.touches = [touch]
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

    func setRTS(_ addRts: Bool? = false) {
        if addRts ?? false {
            self.rts = "targetInteractionEvent"
        }
    }

    func copy(with zone: NSZone? = nil) -> NIDEvent {
        let copy = NIDEvent(
            rawType: self.type
        )

        copy.tg = self.tg
        copy.tgs = self.tgs
        copy.key = self.key
        copy.ct = self.ct
        copy.v = self.v
        copy.hv = self.hv
        copy.en = self.en
        copy.etn = self.etn
        copy.et = self.et
        copy.ec = self.ec
        copy.eid = self.eid
        copy.ts = self.ts
        copy.x = self.x
        copy.y = self.y
        copy.h = self.h
        copy.w = self.w
        copy.f = self.f
        copy.lsid = self.lsid
        copy.sid = self.sid
        copy.cid = self.cid
        copy.did = self.did
        copy.rid = self.rid
        copy.loc = self.loc
        copy.ua = self.ua
        copy.tzo = self.tzo
        copy.lng = self.lng
        copy.p = self.p
        copy.dnt = self.dnt
        copy.tch = self.tch
        copy.url = self.url
        copy.ns = self.ns
        copy.jsl = self.jsl
        copy.jsv = self.jsv
        copy.uid = self.uid
        copy.sm = self.sm
        copy.pd = self.pd
        copy.attrs = self.attrs
        copy.gyro = self.gyro
        copy.accel = self.accel
        copy.touches = self.touches
        copy.metadata = self.metadata
        copy.sh = self.sh
        copy.sw = self.sw
        copy.rts = self.rts
        copy.c = self.c
        copy.cp = self.cp
        copy.iswifi = self.iswifi
        copy.isconnected = self.isconnected

        return copy
    }
}
