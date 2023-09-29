//
//  UIClassExtensionTests.swift
//  SDKTest
//
//  Created by Kevin Sites on 8/31/23.
//

@testable import NeuroID
import XCTest

class UIViewExtensionTests: XCTestCase {
    func assertViewIdEquals(_ view: UIView, expectedValue: String) {
        assert(view.id == expectedValue)
    }

    func assertViewIdEqualsWithHash(_ view: UIView, expectedClass: String, hash: String) {
        assert(view.id == "\(expectedClass)_UNKNOWN_NO_ID_SET_\(hash)")
    }

    func assertViewIdContains(_ view: UIView, expectedValue: String) {
        assert(view.id.contains(expectedValue) == true)
    }

    func assertViewIdUnknownContains(_ view: UIView, expectedClass: String) {
        assertViewIdContains(view, expectedValue: "\(expectedClass)_UNKNOWN_NO_ID_SET")
    }

    func runThroughBasicUIViewTests(uiView: UIView, className: String) {
        // no id set
        assertViewIdUnknownContains(uiView, expectedClass: className)
        // accessibilityIdentifier
        uiView.accessibilityIdentifier = "aiTest"
        assertViewIdEquals(uiView, expectedValue: "aiTest")
        uiView.accessibilityIdentifier = nil

        // id set
        uiView.id = "myTestId"
        assertViewIdEquals(uiView, expectedValue: "myTestId")
        uiView.accessibilityIdentifier = nil
    }

    func test_uiview_subviewsRecursive() {
        let uiView = UIView()
        uiView.addSubview(UITextView())

        let value = uiView.subviewsRecursive()

        assert(value.count == 4)
    }

    func test_uiview_className() {
        let uiView = UIView()

        let value = uiView.nidClassName

        assert(value == "UIView")

        let uiButton = UIButton()

        let valueButton = uiButton.nidClassName

        assert(valueButton == "UIButton")

        let uiText = UITextField()

        let valueText = uiText.nidClassName

        assert(valueText == "UITextField")
    }

    func test_uiview_subviewsDescriptions() {
        let uiView = UIView()
        uiView.addSubview(UITextView())
        uiView.addSubview(UIButton())

        let value = uiView.subviewsDescriptions

        assert(value.count == 2)
    }

    func test_uiview_id_uiView() {
        let className = "UIView"
        let uiView = UIView()

        runThroughBasicUIViewTests(uiView: uiView, className: className)
    }

    func test_uiview_id_UITextField() {
        let className = "UITextField"
        let uiView = UITextField()

        runThroughBasicUIViewTests(uiView: uiView, className: className)

        // placeholder set
        uiView.placeholder = "myPlaceholder"
        assertViewIdEquals(uiView, expectedValue: "myPlaceholder")
    }

    func test_uiview_id_UIDatePicker() {
        let className = "UIDatePicker"
        let uiView = UIDatePicker()

        runThroughBasicUIViewTests(uiView: uiView, className: className)

        assertViewIdEqualsWithHash(uiView, expectedClass: className, hash: "\(uiView.hash)")
    }

    func test_uiview_id_UIButton() {
        let className = "UIButton"
        let uiView = UIButton()

        runThroughBasicUIViewTests(uiView: uiView, className: className)

        assertViewIdEqualsWithHash(uiView, expectedClass: className, hash: "\(uiView.hash)")
    }

    func test_uiview_id_UISlider() {
        let className = "UISlider"
        let uiView = UISlider()

        runThroughBasicUIViewTests(uiView: uiView, className: className)

        assertViewIdEqualsWithHash(uiView, expectedClass: className, hash: "\(uiView.hash)")
    }

    func test_uiview_id_UISegmentedControl() {
        let className = "UISegmentedControl"
        let uiView = UISegmentedControl()

        runThroughBasicUIViewTests(uiView: uiView, className: className)

        assertViewIdEqualsWithHash(uiView, expectedClass: className, hash: "\(uiView.hash)")
    }

    func test_uiview_id_UISwitch() {
        let className = "UISwitch"
        let uiView = UISwitch()

        runThroughBasicUIViewTests(uiView: uiView, className: className)

        assertViewIdEqualsWithHash(uiView, expectedClass: className, hash: "\(uiView.hash)")
    }
}
