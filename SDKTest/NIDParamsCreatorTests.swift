//
//  NIDParamsCreatorTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 3/30/23.
//

@testable import NeuroID
import XCTest

class NIDParamsCreatorTests: XCTestCase {
    // consts
    let tgsKey = Constants.tgsKey.rawValue
    let etKey = Constants.etKey.rawValue
    let etnKey = Constants.etnKey.rawValue
    let attrKey = Constants.attrKey.rawValue

    let uiView = UIView()
    let defaultTargetValue = TargetValue.string("")
    let tgParamsBaseExpectation: [String: TargetValue] = [
        "\(Constants.etnKey.rawValue)": TargetValue.string("UIView"),
        "\(Constants.tgsKey.rawValue)": TargetValue.string("UIView_UNKNOWN_NO_ID_SET")
    ]

    let tgParamType = "text"
    let attrParams: [String: Any] = ["\(Constants.vKey.rawValue)": 4, "\(Constants.hashKey.rawValue)": "test"]

    let clientKey = "key_live_vtotrandom_form_mobilesandbox"

    let extraEntry = ["extra": TargetValue.string("test")]
    let etEntry = ["\(Constants.etKey.rawValue)": TargetValue.string("text")]
    let etnEntry = ["\(Constants.etnKey.rawValue)": TargetValue.string("UIView_UNKNOWN_NO_ID_SET")]
    let etnEntryAlt = ["\(Constants.etnKey.rawValue)": TargetValue.string("TEXT_CHANGE")]
    let kcEntry = ["kc": TargetValue.int(0)]
    let tgsEntry = ["\(Constants.tgsKey.rawValue)": TargetValue.string("UIView_UNKNOWN_NO_ID_SET")]
    let attrEntry = ["\(Constants.attrKey.rawValue)": TargetValue.attr([
        Attr(n: "\(Constants.vKey.rawValue)", v: "\(Constants.eventValuePrefix.rawValue)"),
        Attr(n: "\(Constants.hashKey.rawValue)", v: "6003dfb4")
    ])]

    let valueDoubleEntry = ["value": TargetValue.double(0)]

    override func setUpWithError() throws {
        NeuroID.configure(clientKey: clientKey)
    }

    override func setUp() {
        // Clear out the DataStore Events after each test
        DataStore.removeSentEvents()
    }

    // Util Helper Functions
    func sleep(timeout: Double) {
        let sleep = expectation(description: "Wait \(timeout) seconds.")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeout) {
            sleep.fulfill()
        }
        wait(for: [sleep], timeout: timeout + 1)
    }

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

    func addEntriesToDict(entryList: [String], dictToAddTo: [String: TargetValue]) -> [String: TargetValue] {
        let keyToValueDict: [String: [String: TargetValue]] = [
            "extra": extraEntry,
            "\(etKey)": etEntry,
            "\(etnKey)": etnEntry,
            "etnAlt": etnEntryAlt,
            "kc": kcEntry,
            "\(tgsKey)": tgsEntry,
            "\(attrKey)": attrEntry
        ]

        var newDict = dictToAddTo
        for e in entryList {
            newDict = mergeDictOverwriting(oldDict: newDict, newDict: keyToValueDict[e] ?? ["nil": TargetValue.string("nil")])
        }

        return newDict
    }

    func createUIViewDict(view: UIView, extraValues: [String: TargetValue]) -> [String: TargetValue] {
        var dict: [String: TargetValue] = [:]

        dict["sender"] = TargetValue.string(view.nidClassName)
        dict["\(tgsKey)"] = TargetValue.string(view.id)

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
            if key == "\(tgsKey)" || key == "\(etnKey)" {
                assertTVDictValueContains(v: value[key] ?? defaultTargetValue, ev: evTarget)
            } else {
                assertTVDictValue(v: value[key] ?? defaultTargetValue, ev: evTarget)
            }
        }
    }

    func assertSpecificTVDictKeyValues(keyList: [String], expectedDict: [String: TargetValue], value: [String: TargetValue]) {
        keyList.forEach { key in

            if key == "\(tgsKey)" || key == "\(etnKey)" {
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

    func test_getTGParamsForInput_textInput() {
        var expectedValue = tgParamsBaseExpectation
        expectedValue = addEntriesToDict(entryList: ["\(etKey)", "\(etnKey)", "\(tgsKey)", "\(attrKey)"], dictToAddTo: expectedValue)

        let value = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.textChange, view: uiView, type: tgParamType, attrParams: attrParams)

        assertDictCount(value: value, count: expectedValue.count)
        assertSpecificTVDictKeyValues(keyList: ["\(etKey)", "\(etnKey)", "\(tgsKey)"], expectedDict: expectedValue, value: value)
        assert(value["\(attrKey)"] != nil)
    }

    func test_getTGParamsForInput_textInput_ex() {
        var expectedValue = tgParamsBaseExpectation
        expectedValue = addEntriesToDict(entryList: ["\(etKey)", "\(etnKey)", "\(tgsKey)", "\(attrKey)", "extra"], dictToAddTo: expectedValue)

        let value = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.textChange, view: uiView, type: tgParamType, extraParams: extraEntry, attrParams: attrParams)

        assertDictCount(value: value, count: expectedValue.count)
        assertSpecificTVDictKeyValues(keyList: ["\(etKey)", "\(etnKey)", "\(tgsKey)", "extra"], expectedDict: expectedValue, value: value)
        assert(value["\(attrKey)"] != nil)
    }

    func test_getTGParamsForInput_keyDown() {
        let expectedValue = tgsEntry

        let value = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.keyDown, view: uiView, type: tgParamType, attrParams: attrParams)

        assertDictCount(value: value, count: expectedValue.count)
        assertSpecificTVDictKeyValues(keyList: ["\(tgsKey)"], expectedDict: expectedValue, value: value)
    }

    func test_getTGParamsForInput_keyDown_ex() {
        var expectedValue = tgsEntry
        expectedValue = addEntriesToDict(entryList: ["extra"], dictToAddTo: expectedValue)

        let value = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.keyDown, view: uiView, type: tgParamType, extraParams: extraEntry, attrParams: attrParams)

        assertDictCount(value: value, count: expectedValue.count)
        assertSpecificTVDictKeyValues(keyList: ["\(tgsKey)", "extra"], expectedDict: expectedValue, value: value)
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

    let tidKey = Constants.storageTabIDKey.rawValue
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

    let didKey = Constants.storageDeviceIDKey.rawValue
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
    func test_generateID() {
        let expectedValue = 36

        let value = ParamsCreator.generateID()

        assert(value.count == expectedValue)
    }

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

    func test_generateUniqueHexID() {
        let value = ParamsCreator.generateUniqueHexID()
        assert(value.count >= 7)

        sleep(timeout: 0.2)
        let secondValue = ParamsCreator.generateUniqueHexID()
        assert(secondValue.count >= 7)

        assert(value != secondValue)
    }
}
