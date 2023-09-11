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
    private var className: String?
    private var createSessionEvent: NIDEvent?
    /// Capture letter count of textfield/textview to detect a paste action
    var textCapturing = [String: String]()
    public init(screen: String, controller: UIViewController?) {
        super.init()
        self.screen = screen
        if !NeuroID.isStopped() {
            subscribe(inScreen: controller)
        }
        className = controller?.className
    }
    
    public func captureEvent(event: NIDEvent) {
        let screenName = screen ?? ParamsCreator.genId()
        let newEvent = event
        // Make sure we have a valid url set
        newEvent.url = NeuroID.getScreenName()
        DataStore.insertEvent(screen: screenName, event: newEvent)
    }
    
    public static func registerSingleView(v: Any, screenName: String, guid: String, rts: Bool? = false) {
        let currView = v as? UIView
        
        // constants
        let screenName = NeuroID.getScreenName() ?? screenName
        let fullViewString = UtilFunctions.getFullViewlURLPath(currView: currView, screenName: screenName)
        let baseAttrs = [
            Attrs(n: "\(Constants.attrGuidKey.rawValue)", v: guid),
            Attrs(n: "\(Constants.attrScreenHierarchyKey.rawValue)", v: fullViewString),
        ]
        let tg = [
            "\(Constants.attrKey.rawValue)": TargetValue.attr(
                [
                    Attr(n: "\(Constants.attrScreenHierarchyKey.rawValue)", v: fullViewString),
                    Attr(n: "\(Constants.attrGuidKey.rawValue)", v: guid),
                ]
            ),
        ]
        
        // variables per view type
        var value = ""
        var etn = "INPUT"
        let id = currView?.id ?? ""
        let classname = currView?.className ?? ""
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
                //           @objc func myTargetFunction(textField: UITextField) {     print("myTargetFunction") }
                //            // Add view on top of textfield to get taps
                //            var invisView = UIView.init(frame: element.frame)
                //            invisView.backgroundColor = UIColor(red: 100.0, green: 0.0, blue: 0.0, alpha: 0.0)
                //
                //            invisView.backgroundColor = UIColor(red: 0.8, green: 0.1, blue: 0.5, alpha: 1)
                //            element.addSubview(invisView)
                //            let tap = UITapGestureRecognizer(target: self , action: #selector(self.handleTap(_:)))
                //            invisView.addGestureRecognizer(tap)
                //            invisView.superview?.bringSubviewToFront(invisView)
                //            invisView.superview?.layer.zPosition = 10000000
                
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
                NIDDebugPrint(tag: "NID FE:", "Picker View Found NOT Registered: \(element.className) - \(element.id)- \(element.numberOfComponents) - \(element.tag)")
            case is UITableViewCell:
                // swiftUI list
                let element = v as! UITableViewCell
                NIDDebugPrint(tag: "NID FE:", "TABLE View Found NOT Registered: \(element.className) - \(element.id)-")
            case is UIScrollView:
                let element = v as! UIScrollView
                NIDDebugPrint(tag: "NID FE:", "SCROLL View Found NOT Registered: \(element.className) - \(element.id)-")
                
            default:
                if !found {
                    return
                }
        }
        
        if found {
            UtilFunctions.registerField(textValue: value,
                                        etn: etn,
                                        id: id,
                                        className: classname,
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
            let guid = ParamsCreator.genId()
            NeuroIDTracker.registerSingleView(v: view, screenName: NeuroID.getScreenName() ?? view.className, guid: guid, rts: true)
            return true
        }
        return false
    }
}

internal extension NeuroIDTracker {
    func subscribe(inScreen controller: UIViewController?) {
        // Early exit if we are stopped
        if NeuroID.isStopped() {
            return
        }

        if let views = controller?.view.subviews {
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
