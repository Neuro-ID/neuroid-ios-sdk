import Alamofire
import CommonCrypto
import Foundation
import ObjectiveC
import os
import SwiftUI
import UIKit
import WebKit

// MARK: - NeuroIDTracker

public class NeuroIDTracker: NSObject {
    private var screen: String?
    private var nidClassName: String?
    private var createSessionEvent: NIDEvent?
    
    /// Capture letter count of textfield/textview to detect a paste action
    var textCapturing = [String: String]()
    public init(screen: String, controller: UIViewController?) {
        super.init()
        self.screen = screen
        if !NeuroID.isStopped() {
            subscribe(inScreen: controller)
        }
        nidClassName = controller?.nidClassName
    }

    public func captureEvent(event: NIDEvent) {
        let screenName = screen ?? ParamsCreator.generateID()
        let newEvent = event
        // Make sure we have a valid url set
        newEvent.url = NeuroID.getScreenName()
        NeuroID.saveEventToLocalDataStore(newEvent, screen: screenName)
    }
    
    public static func registerSingleView(
        v: Any,
        screenName: String,
        guid: String,
        rts: Bool? = false,
        topDownHierarchyPath: String
    ) {
        let currView = v as? UIView
        
        // constants
        let screenName = NeuroID.getScreenName() ?? screenName
        let bottomUpHierarchyPath = UtilFunctions.getFullViewlURLPath(currView: currView ?? UIView())
        
        let baseAttrs = [
            Attrs(n: "\(Constants.attrGuidKey.rawValue)", v: guid),
            Attrs(n: "\(Constants.attrScreenHierarchyKey.rawValue)", v: bottomUpHierarchyPath),
            Attrs(n: "top-\(Constants.attrScreenHierarchyKey.rawValue)", v: topDownHierarchyPath),
        ]
        
        let tg = [
            "\(Constants.attrKey.rawValue)": TargetValue.attr(
                [
                    Attr(n: "\(Constants.attrScreenHierarchyKey.rawValue)", v: bottomUpHierarchyPath),
                    Attr(n: "\(Constants.attrGuidKey.rawValue)", v: guid),
                    Attr(n: "top-\(Constants.attrScreenHierarchyKey.rawValue)", v: topDownHierarchyPath),
                ]
            ),
        ]
        
        // variables per view type
        var value = ""
        var etn = "INPUT"
        let id = currView?.id ?? ""
        let nidClassName = currView?.nidClassName ?? ""
        var type = ""
        var extraAttrs: [Attrs] = []
        var rawText = false
        
        // indicate if a supported element was found
        var found = false
        
        if #available(iOS 14.0, *) {
            switch v {
                case is UIColorWell:
                    let _ = v as! UIColorWell
                    
                    value = ""
                    type = "UIColorWell"
                    
                    found = true
                    
                default:
                    let _ = ""
            }
        }
        
        switch v {
            case is UITextField:
                let element = v as! UITextField
                element.addTapGesture()
                
                value = element.text ?? ""
                type = "UITextField"
                
                found = true
                
            case is UITextView:
                let element = v as! UITextView
                element.addTapGesture()
                
                value = element.text ?? ""
                type = "UITextView"
                
                found = true
                
            case is UIButton:
                let element = v as! UIButton
                
                value = element.titleLabel?.text ?? ""
                etn = "BUTTON"
                type = "UIButton"
                
                found = true
                
            case is UISlider:
                let element = v as! UISlider
                
                value = "\(element.value)"
                type = "UISlider"
                extraAttrs = [
                    Attrs(n: "minValue", v: "\(element.minimumValue)"),
                    Attrs(n: "maxValue", v: "\(element.maximumValue)"),
                ]
                
                found = true
                
            case is UISwitch:
                let element = v as! UISwitch
                
                value = "\(element.isOn)"
                type = "UISwitch"
                rawText = true
                
                found = true
                
            case is UIDatePicker:
                let element = v as! UIDatePicker
                
                value = "\(element.date.toString())"
                type = "UIDatePicker"
                
                found = true
                
            case is UIStepper:
                let element = v as! UIStepper
                
                value = "\(element.value)"
                type = "UIStepper"
                extraAttrs = [
                    Attrs(n: "minValue", v: "\(element.minimumValue)"),
                    Attrs(n: "maxValue", v: "\(element.maximumValue)"),
                ]
                
                found = true
                
            case is UISegmentedControl:
                let element = v as! UISegmentedControl
                
                value = "\(element.selectedSegmentIndex)"
                type = "UISegmentedControl"
                extraAttrs = [
                    Attrs(n: "totalOptions", v: "\(element.numberOfSegments)"),
                    Attrs(n: "selectedIndex", v: "\(element.selectedSegmentIndex)"),
                ]
                rawText = true
                
                found = true
                
            // UNSUPPORTED AS OF RIGHT NOW
            case is UIPickerView:
                let element = v as! UIPickerView
                NeuroID.logger.d(tag: "NeuroID FE:", "Picker View Found NOT Registered: \(element.nidClassName) - \(element.id)- \(element.numberOfComponents) - \(element.tag)")

            case is UITableViewCell:
                // swiftUI list
                let element = v as! UITableViewCell
                NeuroID.logger.d(tag: "NeuroID FE:", "Table View Found NOT Registered: \(element.nidClassName) - \(element.id)-")

            case is UIScrollView:
                let element = v as! UIScrollView
                NeuroID.logger.d(tag: "NeuroID FE:", "Scroll View Found NOT Registered: \(element.nidClassName) - \(element.id)-")
                
            default:
                if !found {
                    // Capture custom RN elements that have a testID set
                    if NeuroID.isRN && !id.contains("UNKNOWN_NO_ID_SET") {
                        value = id
                        etn = "ELEMENT"
                        type = "ReactNativeElement"
                        
                        found = true
                    } else {
                        return
                    }
                }
        }
        
        if found {
            UtilFunctions.registerField(textValue: value,
                                        etn: etn,
                                        id: id,
                                        className: nidClassName,
                                        type: type,
                                        screenName: screenName,
                                        tg: tg,
                                        attrs: baseAttrs + extraAttrs,
                                        rts: rts,
                                        rawText: rawText)
        }
        // Text
        // Inputs
        // Checkbox/Radios inputs
    }
    
    static func registerViewIfNotRegistered(view: UIView) -> Bool {
        if !NeuroID.registeredTargets.contains(view.id) {
            NeuroID.registeredTargets.append(view.id)
            let guid = ParamsCreator.generateID()
            
            NeuroIDTracker.registerSingleView(
                v: view,
                screenName: NeuroID.getScreenName() ?? view.nidClassName,
                guid: guid,
                rts: true,
                topDownHierarchyPath: ""
            )
            return true
        }
        return false
    }
}

extension NeuroIDTracker {
    func subscribe(inScreen controller: UIViewController?) {
        // Early exit if we are stopped
        if NeuroID.isStopped() {
            return
        }

        if let views = controller?.viewIfLoaded?.subviews {
            observeViews(views)
        }

        // Only run observations on first run
        if !NeuroID.observingInputs {
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
