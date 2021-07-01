import Foundation

internal enum NISessionEventName: String {
    case createSession = "CREATE_SESSION"
    case stateChange = "STATE_CHANGE"
    case setUserId = "SET_USER_ID"
    case setVariable = "SET_VARIABLE"
    case tag = "TAG"
    case setCheckPoint = "SET_CHECKPOINT"
    case setCustomEvent = "SET_CUSTOM_EVENT"
    case heartBeat = "HEARTBEAT"

    func log() {
        let event = NIEvent(session: self, tg: nil, x: nil, y: nil)
        NeuroID.log(event)
    }
}

public enum NIEventName: String {
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
}

public struct NIEvent {
    let type: String
    let tg: [String: Any?]?
    let ts = Date().timeIntervalSince1970 * 1000
    let x: Int?
    let y: Int?

    init(session: NISessionEventName, tg: [String: Any?]?, x: Int?, y: Int?) {
        type = session.rawValue
        self.tg = tg
        self.x = x
        self.y = y
    }

    init(type: NIEventName, tg: [String: Any?]?, x: Int?, y: Int?) {
        self.type = type.rawValue
        self.tg = tg
        self.x = x
        self.y = y
    }

    init(customEvent: String, tg: [String: Any?]?, x: Int?, y: Int?) {
        type = customEvent
        self.tg = tg
        self.x = x
        self.y = y
        NeuroID.log(NIEvent(session: .setCustomEvent, tg: tg, x: x, y: y))
    }

    func toDict() -> [String: Any] {
        var dict = [String: Any]()
        dict["type"] = type
        dict["ts"] = ts
        if let data = x {
            dict["x"] = data
        }

        if let data = y {
            dict["y"] = data
        }

        var dictTg = [String: Any]()
        if let tg = tg {
            for (key, value) in tg where value != nil {
                dictTg[key] = value
            }
        }

        dict["tg"] = dictTg
        return dict
    }

    func toBase64() -> String? {
        var dict = [String: Any]()
        dict["type"] = type
        dict["ts"] = ts
        if let data = x {
            dict["x"] = data
        }

        if let data = y {
            dict["y"] = data
        }

        var dictTg = [String: Any]()
        if let tg = tg {
            for (key, value) in tg where value != nil {
                dictTg[key] = value
            }
        }

        dict["tg"] = dictTg

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
