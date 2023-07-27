//
//  NIDParamsCreatorTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 3/30/23.
//

@testable import NeuroID
import XCTest

class NIDParamsCreatorTests: XCTestCase {
    let uiView = UIView()
    let defaultTargetValue = TargetValue.string("")
    let tgParamsBaseExpectation: [String: TargetValue] = [
        "etn": TargetValue.string("UIView"),
        "tgs": TargetValue.string("UIView_UNKNOWN_NO_ID_SET")
    ]

    let tgParamType = "text"
    let attrParams: [String: Any] = ["v": 4, "hash": "test"]

    let clientKey = "key_live_vtotrandom_form_mobilesandbox"

    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey)
    }

    override func setUp() {
        // Clear out the DataStore Events after each test
        DataStore.removeSentEvents()
    }

    // Util Helper Functions
    func createStringTargetValue(v: String) -> TargetValue {
        return TargetValue.string(v)
    }

    func createIntTargetValue(v: Int) -> TargetValue {
        return TargetValue.int(v)
    }

    func mergeDictOverwriting(oldDict: [String: TargetValue], newDict: [String: TargetValue]) -> [String: TargetValue] {
        let combinedDict = oldDict.merging(newDict) { _, new in new }

        return combinedDict
    }

    let extraEntry = ["extra": TargetValue.string("test")]
    let etEntry = ["et": TargetValue.string("text")]
    let etnEntry = ["etn": TargetValue.string("UIView_UNKNOWN_NO_ID_SET")]
    let etnEntryAlt = ["etn": TargetValue.string("TEXT_CHANGE")]
    let kcEntry = ["kc": TargetValue.int(0)]
    let tgsEntry = ["tgs": TargetValue.string("UIView_UNKNOWN_NO_ID_SET")]
    let attrEntry = ["attr": TargetValue.attr([
        Attr(n: "v", v: "\(Constants.eventValuePrefix.rawValue)"),
        Attr(n: "hash", v: "6003dfb4")
    ])]

    let valueDoubleEntry = ["value": TargetValue.double(0)]

    func addEntriesToDict(entryList: [String], dictToAddTo: [String: TargetValue]) -> [String: TargetValue] {
        let keyToValueDict: [String: [String: TargetValue]] = [
            "extra": extraEntry,
            "et": etEntry,
            "etn": etnEntry,
            "etnAlt": etnEntryAlt,
            "kc": kcEntry,
            "tgs": tgsEntry,
            "attr": attrEntry
        ]

        var newDict = dictToAddTo
        for e in entryList {
            newDict = mergeDictOverwriting(oldDict: newDict, newDict: keyToValueDict[e] ?? ["nil": TargetValue.string("nil")])
        }

        return newDict
    }

    func createUIViewDict(view: UIView, extraValues: [String: TargetValue]) -> [String: TargetValue] {
        var dict: [String: TargetValue] = [:]

        dict["sender"] = TargetValue.string(view.className)
        dict["tgs"] = TargetValue.string(view.id)

        dict = dict.merging(extraValues) { _, new in new }

        return dict
    }

    // Assert Helper Functions
    func assertDictCount(value: [String: Any], count: Int) {
        assert(value.count == count)
    }

    func assertStringDictValue(v: String, ev: String) {
        assert(v == ev)
    }

    func assertExpectedStringDictValues(expected: [String: String], value: [String: String]) {
        assertDictCount(value: value, count: expected.count)

        expected.forEach { (key: String, evTarget: String) in
            assertStringDictValue(v: value[key] ?? "", ev: evTarget)
        }
    }

    func assertTVDictValue(v: TargetValue, ev: TargetValue) {
        assert(v == ev)
    }

    func assertTVDictValueContains(v: TargetValue, ev: TargetValue) {
        assert(v.toString().contains(ev.toString()))
    }

    func assertExpectedTVDictValues(expected: [String: TargetValue], value: [String: TargetValue]) {
        assertDictCount(value: value, count: expected.count)

        expected.forEach { (key: String, evTarget: TargetValue) in
            if key == "tgs" || key == "etn" {
                assertTVDictValueContains(v: value[key] ?? defaultTargetValue, ev: evTarget)
            } else {
                assertTVDictValue(v: value[key] ?? defaultTargetValue, ev: evTarget)
            }
        }
    }

    func assertSpecificTVDictKeyValues(keyList: [String], expectedDict: [String: TargetValue], value: [String: TargetValue]) {
        keyList.forEach { key in

            if key == "tgs" || key == "etn" {
                assertTVDictValueContains(v: value[key] ?? defaultTargetValue, ev: expectedDict[key] ?? defaultTargetValue)
            } else {
                assertTVDictValue(v: value[key] ?? defaultTargetValue, ev: expectedDict[key] ?? defaultTargetValue)
            }
        }
    }

    func assertAttrArrayValues(expected: [Attr], value: [Attr]) {
        for (index, element) in expected.enumerated() {
            assert(element.v == value[index].v)
            assert(element.hash == value[index].hash)
        }
    }

    func test_getTgParams_og() {
        let expectedValue = tgParamsBaseExpectation

        let value = ParamsCreator.getTgParams(view: uiView)

        assertExpectedTVDictValues(expected: expectedValue, value: value)
    }

    func test_getTgParams_ex() {
        var expectedValue = tgParamsBaseExpectation
        expectedValue = addEntriesToDict(entryList: ["extra"], dictToAddTo: expectedValue)

        let value = ParamsCreator.getTgParams(view: uiView, extraParams: extraEntry)

        assertExpectedTVDictValues(expected: expectedValue, value: value)
    }

    func test_getTimeStamp() {
        let value = ParamsCreator.getTimeStamp()
        assert(value != 0)
    }

    func test_getTextTgParams_og() {
        var expectedValue = tgParamsBaseExpectation
        expectedValue = addEntriesToDict(entryList: ["etnAlt", "kc"], dictToAddTo: expectedValue)

        let value = ParamsCreator.getTextTgParams(view: uiView)

        assertExpectedTVDictValues(expected: expectedValue, value: value)
    }

    func test_getTextTgParams_ex() {
        var expectedValue = tgParamsBaseExpectation
        expectedValue = addEntriesToDict(entryList: ["etnAlt", "kc", "extra"], dictToAddTo: expectedValue)

        let value = ParamsCreator.getTextTgParams(view: uiView, extraParams: extraEntry)

        assertExpectedTVDictValues(expected: expectedValue, value: value)
    }

    func test_getTGParamsForInput_textInput() {
        var expectedValue = tgParamsBaseExpectation
        expectedValue = addEntriesToDict(entryList: ["et", "etn", "tgs", "attr"], dictToAddTo: expectedValue)

        let value = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.textChange, view: uiView, type: tgParamType, attrParams: attrParams)

        assertDictCount(value: value, count: expectedValue.count)
        assertSpecificTVDictKeyValues(keyList: ["et", "etn", "tgs"], expectedDict: expectedValue, value: value)
        assert(value["attr"] != nil)
    }

    func test_getTGParamsForInput_textInput_ex() {
        var expectedValue = tgParamsBaseExpectation
        expectedValue = addEntriesToDict(entryList: ["et", "etn", "tgs", "attr", "extra"], dictToAddTo: expectedValue)

        let value = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.textChange, view: uiView, type: tgParamType, extraParams: extraEntry, attrParams: attrParams)

        assertDictCount(value: value, count: expectedValue.count)
        assertSpecificTVDictKeyValues(keyList: ["et", "etn", "tgs", "extra"], expectedDict: expectedValue, value: value)
        assert(value["attr"] != nil)
    }

    func test_getTGParamsForInput_keyDown() {
        let expectedValue = tgsEntry

        let value = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.keyDown, view: uiView, type: tgParamType, attrParams: attrParams)

        assertDictCount(value: value, count: expectedValue.count)
        assertSpecificTVDictKeyValues(keyList: ["tgs"], expectedDict: expectedValue, value: value)
    }

    func test_getTGParamsForInput_keyDown_ex() {
        var expectedValue = tgsEntry
        expectedValue = addEntriesToDict(entryList: ["extra"], dictToAddTo: expectedValue)

        let value = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.keyDown, view: uiView, type: tgParamType, extraParams: extraEntry, attrParams: attrParams)

        assertDictCount(value: value, count: expectedValue.count)
        assertSpecificTVDictKeyValues(keyList: ["tgs", "extra"], expectedDict: expectedValue, value: value)
    }

    func test_getUiControlTgParams_UISwitch() {
        let uiView = UISwitch()
        let expectedValue = createUIViewDict(view: uiView, extraValues: mergeDictOverwriting(oldDict: ["oldValue": TargetValue.bool(true)], newDict: ["newValue": TargetValue.bool(false)]))

        let value = ParamsCreator.getUiControlTgParams(sender: uiView)

        assertExpectedTVDictValues(expected: expectedValue, value: value)
    }

    // Setting Title Fails?
//    func test_getUiControlTgParams_UISegmentedControl() {
//        let uiView = UISegmentedControl()
//        let expectedValue = createUIViewDict(view: uiView)
//
//        let value = ParamsCreator.getUiControlTgParams(sender: uiView)
//
//        assertExpectedTVDictValues(expected: expectedValue, value: value)
//    }

    func test_getUiControlTgParams_UIStepper() {
        let uiView = UIStepper()
        let expectedValue = createUIViewDict(view: uiView, extraValues: valueDoubleEntry)

        let value = ParamsCreator.getUiControlTgParams(sender: uiView)

        assertExpectedTVDictValues(expected: expectedValue, value: value)
    }

    func test_getUiControlTgParams_UISlider() {
        let uiView = UISlider()
        let expectedValue = createUIViewDict(view: uiView, extraValues: valueDoubleEntry)

        let value = ParamsCreator.getUiControlTgParams(sender: uiView)

        assertExpectedTVDictValues(expected: expectedValue, value: value)
    }

    func test_getUiControlTgParams_UIDatePicker() {
        let uiView = UIDatePicker()
        let expectedValue = createUIViewDict(view: uiView, extraValues: ["value": TargetValue.string("\(Constants.eventValuePrefix.rawValue)19")])

        let value = ParamsCreator.getUiControlTgParams(sender: uiView)

        assertExpectedTVDictValues(expected: expectedValue, value: value)
    }

    // Test Runs forever because of UIPasteBoard?
//    func test_getCopyTgParams() {
//        let expectedValue = ["content": TargetValue.string("")]
//
//        let value = ParamsCreator.getCopyTgParams()
//
//        assertDictCount(value: value, count: expectedValue.count)
//        assertExpectedTVDictValues(expected: expectedValue, value: value)
//    }

    func test_getOrientationChangeTgParams() {
        let expectedValue = ["orientation": Constants.orientationPortrait.rawValue]

        let value = ParamsCreator.getOrientationChangeTgParams()

        assertDictCount(value: value as [String: Any], count: expectedValue.count)
        assertStringDictValue(v: value["orientation"] as! String, ev: expectedValue["orientation"] ?? "")
    }

    func test_getDefaultSessionParams() {
        let value = ParamsCreator.getDefaultSessionParams()

        assertDictCount(value: value as [String: Any], count: 7)
        // Unsure how to verify the default params
    }

    func test_getClientKey() {
        let expectedValue = clientKey

        let value = ParamsCreator.getClientKey()

        assertStringDictValue(v: value, ev: expectedValue)
    }

    let sidKeyName = Constants.storageSiteIdKey.rawValue
    func test_getSessionID_existing() {
        let expectedValue = "test_sid"

        UserDefaults.standard.set(expectedValue, forKey: sidKeyName)

        let value = ParamsCreator.getSessionID()

        assert(value == expectedValue)
    }

    func test_getSessionID_random() {
        let expectedValue = ""

        UserDefaults.standard.set(expectedValue, forKey: sidKeyName)

        let value = ParamsCreator.getSessionID()

        assert(value == expectedValue)
    }

    let sidExpiresKey = Constants.storageSessionExpiredKey.rawValue
    func test_isSessionExpired_true() {
        let expectedValue = true

        UserDefaults.standard.set(1, forKey: sidExpiresKey)

        let value = ParamsCreator.isSessionExpired()

        assert(value == expectedValue)
    }

    func test_isSessionExpired_false() {
        let expectedValue = false

        UserDefaults.standard.set(Date(), forKey: sidExpiresKey)

        let value = ParamsCreator.isSessionExpired()

        assert(value == expectedValue)
    }

    func test_setSessionExpireTime() {
        let expectedValue = false

        let value = ParamsCreator.setSessionExpireTime()

        assert(value != 0)

        let expired = ParamsCreator.isSessionExpired()
        assert(expired == expectedValue)
    }

    let cidKey = Constants.storageClientKeyAlt.rawValue
    func test_getClientId_existing() {
        let expectedValue = "test-cid"

        NeuroID.clientId = expectedValue
        UserDefaults.standard.set(expectedValue, forKey: cidKey)

        let value = ParamsCreator.getClientId()

        assert(value == expectedValue)
    }

    func test_getClientId_random() {
        let expectedValue = "test_cid"

        UserDefaults.standard.set(expectedValue, forKey: cidKey)

        let value = ParamsCreator.getClientId()

        assert(value != expectedValue)
    }

    let tidKey = Constants.storageTabIdKey.rawValue
    func test_getTabId_existing() {
        let expectedValue = "test_tid"

        UserDefaults.standard.set(expectedValue, forKey: tidKey)

        let value = ParamsCreator.getTabId()

        assert(value == expectedValue)
    }

    func test_getTabId_random() {
        let expectedValue = "test-tid"

        UserDefaults.standard.set(expectedValue, forKey: tidKey)

        let value = ParamsCreator.getTabId()

        assert(value != expectedValue)
    }

    let uidKey = Constants.storageUserIdKey.rawValue
    func test_getUserID_existing() {
        let expectedValue = "test_uid"

        UserDefaults.standard.set(expectedValue, forKey: uidKey)

        let value = ParamsCreator.getUserID()

        assert(value == expectedValue)
    }

    func test_getUserID_random() {
        let expectedValue = "test_uid"

        NeuroID.start()

        try? NeuroID.setUserID("random")

        let value = ParamsCreator.getUserID()

        assert(value != expectedValue)

        NeuroID.stop()
    }

    let didKey = Constants.storageDeviceIdKey.rawValue
    func test_getDeviceId_existing() {
        let expectedValue = "test_did"

        UserDefaults.standard.set(expectedValue, forKey: didKey)

        let value = ParamsCreator.getDeviceId()

        assert(value == expectedValue)
    }

    func test_getDeviceId_random() {
        let expectedValue = "test-did"

        UserDefaults.standard.set(expectedValue, forKey: didKey)

        let value = ParamsCreator.getDeviceId()

        assert(value != expectedValue)
    }

    // Private Access Level
//    func test_genId() {
//        let expectedValue = 12
//
//        let value = ParamsCreator.genId()
//
//        assert(value.count() == expectedValue)
//    }

    let dntKey = Constants.storageDntKey.rawValue
    func test_getDnt_existing() {
        let expectedValue = true

        UserDefaults.standard.set(expectedValue, forKey: dntKey)

        let value = ParamsCreator.getDnt()

        assert(value == expectedValue)
    }

    func test_getDnt_random() {
        let expectedValue = false

        UserDefaults.standard.removeObject(forKey: dntKey)

        let value = ParamsCreator.getDnt()

        assert(value == expectedValue)
    }

    func test_getTouch() {
        let expectedValue = true

        let value = ParamsCreator.getTouch()

        assert(value == expectedValue)
    }

    func test_getPlatform() {
        let expectedValue = "Apple"

        let value = ParamsCreator.getPlatform()

        assert(value == expectedValue)
    }

    func test_getLocale() {
        let expectedValue = Locale.current.identifier

        let value = ParamsCreator.getLocale()

        assert(value == expectedValue)
    }

    func test_getUserAgent() {
        let expectedValue = "iOS " + UIDevice.current.systemVersion

        let value = ParamsCreator.getUserAgent()

        assert(value == expectedValue)
    }

    func test_getTimezone() {
        let expectedValue = TimeZone.current.secondsFromGMT() / 60

        let value = ParamsCreator.getTimezone()

        assert(value == expectedValue)
    }

    func test_getLanguage() {
        let expectedValue = Locale.current.languageCode ?? Locale.current.identifier

        let value = ParamsCreator.getLanguage()

        assert(value == expectedValue)
    }

    func test_getSDKVersion() {
        let version = Bundle(for: NeuroIDTracker.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let expectedValue = "5.ios-\(version ?? "?")"

        let value = ParamsCreator.getSDKVersion()

        assert(value == expectedValue)
    }

    func test_getCommandQueueNamespace() {
        let expectedValue = "nid"

        let value = ParamsCreator.getCommandQueueNamespace()

        assert(value == expectedValue)
    }

    func test_generateUniqueHexId() {
        let value = ParamsCreator.generateUniqueHexId()

        assert(value != nil)
    }
}
