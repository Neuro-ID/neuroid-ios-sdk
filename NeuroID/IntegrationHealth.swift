//
//  IntegrationHealth.swift
//  NeuroID
//
//  Created by Kevin Sites on 4/20/23.
//

import Foundation
import UIKit

internal struct EventIntegration {
    let target: String
    var registered: [NIDEvent] = []
    var blur: [NIDEvent] = []
    var focus: [NIDEvent] = []
    var input: [NIDEvent] = []
    var inputChange: [NIDEvent] = []
    var textChange: [NIDEvent] = []

    var createSession: [NIDEvent] = []

    init(_ target: String) {
        self.target = target
    }

    mutating func addEvent(_ event: NIDEvent) {
        switch event.type {
            case NIDEventName.createSession.rawValue:
                self.createSession.append(event)

            case NIDEventName.registerTarget.rawValue:
                self.registered.append(event)

            case NIDEventName.blur.rawValue:
                self.blur.append(event)

            case NIDEventName.focus.rawValue:
                self.focus.append(event)

            case NIDEventName.input.rawValue:
                self.input.append(event)

            case NIDEventName.inputChange.rawValue:
                self.inputChange.append(event)

            case NIDEventName.textChange.rawValue:
                self.textChange.append(event)
            default:
                print("not recognized")
        }
    }
}

func formatDate(date: Date) -> String {
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd hh:mm:ss"
    let now = df.string(from: date)

    return now
}

func createFile(fileName: String, content: String) {
    let fileMang = FileManager.default
    var filePath = NSHomeDirectory()
    do {
        let appSupportDir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        filePath = appSupportDir.appendingPathComponent(fileName).path
    }
    catch {}
    print("Saving Integration Health File at: \(filePath)")
    if fileMang.fileExists(atPath: filePath) {
        do {
            try fileMang.removeItem(atPath: filePath)
        }
        catch {}
    }

    let test = fileMang.createFile(atPath: filePath, contents: content.data(using: String.Encoding.utf8), attributes: nil)
    print("File Saved: \(test)")
}

func generateHTMLHeader(tables: [String] = ["EventTable"]) -> String {
    var tableString = ""

    for tableName in tables {
        tableString += """
            $('#\(tableName.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: ""))').DataTable();
        """
    }

    return """
    <head>
        <link rel="stylesheet" href="https://cdn.datatables.net/1.13.4/css/jquery.dataTables.css" />

        <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.4/jquery.min.js"></script>
        <script src="https://cdn.datatables.net/1.13.4/js/jquery.dataTables.js"></script>
        <script>
            $(document).ready( function () {
                \(tableString)
            } );
        </script>
    </head>
    """
}

func generateHTMLTable(tableName: String, columns: [String], tableContent: String) -> String {
    var columnString = ""
    for column in columns {
        columnString += "<th>\(column)</th>"
    }

    return """
        <h3>\(tableName)</h3>
        <table id="\(tableName.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: ""))" class="display">
            <caption>\(tableName)</caption>
            <thead>
                <tr>
                    \(columnString)
                </tr>
            </thead>
            <tbody>
                   \(tableContent)
            </tbody>
        </table>
    """
}

func formatEventRows(events: [NIDEvent], rowFormatFn: (_: EventIntegration, _: Double) -> String) -> String {
    var targetDict: [String: EventIntegration] = [:]
    for e in events {
//        let eDict = e.asDictionary
        let targetName = (e.tg?["tgs"]?.toString() ?? "NO_ID")

        if targetDict[targetName] != nil {
            targetDict[targetName]?.addEvent(e)
        }
        else {
            targetDict[targetName] = EventIntegration(targetName)
            targetDict[targetName]?.addEvent(e)
        }
    }

    var eventContent = ""
    var eventCount: Double = 0
    for target in targetDict.values {
        let row = rowFormatFn(target, eventCount)
        eventContent += row

        eventCount += 1
    }

//    for event in events {}

    return eventContent
}

func generateGeneralSessionEvents(_ events: [NIDEvent]) -> String {
//    var eventContent = formatEventRows(events: events) { event, eventCount in
//        """
//            <tr>
//                <td>\(event.type)</td>
//                <td>\(formatDate(date: Date() + eventCount))</td>
//                <td></td>
//            </tr>
//        """
//    }

    var eventContent = ""

    return generateHTMLTable(tableName: "General Session Markers", columns: ["Event Type", "Timestamp", "Additional"], tableContent: eventContent)
}

func generateTargetEvents(_ events: [NIDEvent]) -> String {
    let eventContent = formatEventRows(events: events) { event, eventCount in
        """
            <tr>
                <td>\(event.target)</td>
                <td>\(event.registered.count > 0 ? "true" : "false")</td>
                <td>\(event.blur.count)</td>
                <td>\(event.focus.count)</td>
                <td>\(event.input.count)</td>
                <td>\(event.inputChange.count)</td>
                <td>\(event.textChange.count)</td>
                <td>\(formatDate(date: Date() + eventCount))</td>
            </tr>
        """
    }

    return generateHTMLTable(tableName: "Target Events",
                             columns: ["Target", "Registered", "Blur",
                                       "Focus", "Input", "Input Change",
                                       "Text Change", "Observed"],
                             tableContent: eventContent)
}

func generateIntegrationHealthReport() {
//    let events = NeuroID.getIntegrationHealthEvents()
    let events: [NIDEvent] = generateEvents()

    let fileName = "\(formatDate(date: Date()))-integration.html"

    let mainContent = """
    <html>
        \(generateHTMLHeader(tables: ["General Session Markers", "Target Events"]))
        <body style="max-width: 92%; margin: 0px 2%">
            </br>
            <h1>Integration Health Report</h1>
            <p>SDK Version: \(NeuroID.getSDKVersion() ?? "1.0.0")</p>
            </br>

            \(generateGeneralSessionEvents(events))

            </br>
            </br>
            \(generateTargetEvents(events))
        </body>
    <html>
    """

    createFile(fileName: fileName, content: mainContent)
}

func generateEvents() -> [NIDEvent] {
    let textControl = UITextField()
    textControl.accessibilityIdentifier = "text 1"
    textControl.text = "test Text"

    let textControl2 = UITextField()
    textControl2.accessibilityIdentifier = "text 2"
    textControl2.text = "test Text 2"

    let events = [generateEvent(textControl), generateEvent(textControl, NIDEventName.input),
                  generateEvent(textControl, NIDEventName.textChange), generateEvent(textControl, NIDEventName.registerTarget),
                  generateEvent(textControl, NIDEventName.applicationSubmit), generateEvent(textControl, NIDEventName.createSession),
                  generateEvent(textControl, NIDEventName.blur),

                  generateEvent(textControl2), generateEvent(textControl2, NIDEventName.input),
                  generateEvent(textControl2, NIDEventName.textChange), generateEvent(textControl2, NIDEventName.registerTarget),
                  generateEvent(textControl2, NIDEventName.applicationSubmit), generateEvent(textControl2, NIDEventName.createSession),
                  generateEvent(textControl2, NIDEventName.blur)]

    return events
}

func generateEvent(_ target: UIView, _ eventType: NIDEventName = NIDEventName.textChange) -> NIDEvent {
//    let textValue = target.text ?? ""
//    let lengthValue = "S~C~~\(target.text?.count ?? 0)"

    // Text Change
    let textChangeTG = ["tgs": TargetValue.string(target.id)]
    let textChangeEvent = NIDEvent(type: eventType, tg: textChangeTG)

    return textChangeEvent
}
