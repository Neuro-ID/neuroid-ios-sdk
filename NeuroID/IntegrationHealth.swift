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
    let pageUrl: String
    var registered: [NIDEvent] = []
    var blur: [NIDEvent] = []
    var focus: [NIDEvent] = []
    var input: [NIDEvent] = []
    var inputChange: [NIDEvent] = []
    var textChange: [NIDEvent] = []
    var touchStart: [NIDEvent] = []

    var createSession: [NIDEvent] = []

    var urls: [String] = []

    init(_ target: String, _ pageUrl: String) {
        self.target = target
        self.pageUrl = pageUrl
    }

    mutating func addEvent(_ event: NIDEvent) {
        switch event.type {
            case NIDEventName.createSession.rawValue:
                self.createSession.append(event)
                self.addUrl(event.url ?? "NO_URL")

            case NIDEventName.registerTarget.rawValue:
                self.registered.append(event)
                self.addUrl(event.url ?? "NO_URL")

            case NIDEventName.blur.rawValue:
                self.blur.append(event)
                self.addUrl(event.url ?? "NO_URL")

            case NIDEventName.focus.rawValue:
                self.focus.append(event)
                self.addUrl(event.url ?? "NO_URL")

            case NIDEventName.input.rawValue:
                self.input.append(event)
                self.addUrl(event.url ?? "NO_URL")

            case NIDEventName.inputChange.rawValue:
                self.inputChange.append(event)
                self.addUrl(event.url ?? "NO_URL")

            case NIDEventName.textChange.rawValue:
                self.textChange.append(event)
                self.addUrl(event.url ?? "NO_URL")

            case NIDEventName.touchStart.rawValue:
                self.touchStart.append(event)
                self.addUrl(event.url ?? "NO_URL")

            default:
                print("not recognized \(event.type)")
        }
    }

    private mutating func addUrl(_ url: String) {
        if !self.urls.contains(url) {
            self.urls.append(url)
        }
    }
}

func formatDate(date: Date) -> String {
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd hh-mm-ss"
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

func addBreakLines(_ content: String, _ add: Bool = false) -> String {
    return add ? "</br></br> \(content)" : content
}

func generateHTMLHeader(tables: [String] = ["EventTable"]) -> String {
    var tableString = ""

    for tableName in tables {
        tableString += """
            $('#\(tableName.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: ""))').DataTable({
                        "scrollY": "800px",
                        "scrollCollapse": true,
                    });
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

func generateHeaderSection() -> String {
    return """
        <section>
            <h1>Integration Health Report</h1>
            <p>SDK Version: \(NeuroID.getSDKVersion() ?? "1.0.0")</p>
        </section>
    """
}

func generateHTMLTable(tableName: String, columns: [String], tableContent: String) -> String {
    var columnString = ""
    for column in columns {
        columnString += "<th>\(column)</th>"
    }

    return """
        <h3>\(tableName)</h3>
        <table id="\(tableName.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: ""))" class="display" data-page-length="25">
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
        let targetName = (e.tg?["tgs"]?.toString() ?? e.tgs ?? "NO_ID")

        if targetDict[targetName] != nil {
            targetDict[targetName]?.addEvent(e)
        }
        else {
            print("Adding Target: -\(targetName)- \(e.url ?? "url") - \(e.type)")
            targetDict[targetName] = EventIntegration(targetName, e.url ?? "NO_URL")
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

    return eventContent
}

func generateGeneralSessionEvents(_ events: [NIDEvent], addBreakLinesBool: Bool = false) -> String {
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

    return addBreakLines(generateHTMLTable(tableName: "General Session Markers", columns: ["Event Type", "Timestamp", "Additional"], tableContent: eventContent), addBreakLinesBool)
}

func generateTargetEvents(_ events: [NIDEvent], addBreakLinesBool: Bool = false) -> String {
    let eventContent = formatEventRows(events: events) { event, eventCount in
        """
            <tr>
                <td>\(event.target)</td>
                <td>\(event.pageUrl) \(event.urls.count > 1 ? "(+\(event.urls.count))" : "")</td>
                <td>\(event.registered.count)</td>
                <td>\(event.blur.count)</td>
                <td>\(event.focus.count)</td>
                <td>\(event.input.count)</td>
                <td>\(event.inputChange.count)</td>
                <td>\(event.textChange.count)</td>
                <td>\(event.touchStart.count)</td>
                <td>\(formatDate(date: Date() + eventCount))</td>
            </tr>
        """
    }

    return addBreakLines(generateHTMLTable(tableName: "Target Events",
                                           columns: ["Target", "URL", "Registered", "Blur",
                                                     "Focus", "Input", "Input Change",
                                                     "Text Change", "Touch Start", "Observed"],
                                           tableContent: eventContent), addBreakLinesBool)
}

func generateRawEventsTable(_ events: [NIDEvent], addBreakLinesBool: Bool = false) -> String {
    var eventContent = ""
    for event in events {
        eventContent += """
            <tr>
                <td>\(event.tg?["tgs"]?.toString() ?? event.tgs ?? "NO_ID")</td>
                <td>\(event.type)</td>
                <td>\(event.et ?? "NO_ET")</td>
                <td>\(event.url ?? "no_url")</td>
                <td>\(event.toDict().toKeyValueString())</td>
                <td>\(formatDate(date: Date()))</td>
            </tr>
        """
    }

    return addBreakLines(generateHTMLTable(tableName: "Raw Target Events",
                                           columns: ["Target", "Type", "ET",
                                                     "Url", "Raw", "Observed"],
                                           tableContent: eventContent), addBreakLinesBool)
}

func generateIntegrationHealthReport() {
    let events = NeuroID.getIntegrationHealthEvents()
//    let events: [NIDEvent] = generateEvents()

    let fileName = "\(formatDate(date: Date()))-integration.html"

    let mainContent = """
    <html>
        \(generateHTMLHeader(tables: [
            "General Session Markers",
            "Target Events",
            "Raw Target Events",
        ]
        ))
        <body style="max-width: 92%; margin: 0px 2%">
            </br>
            \(generateHeaderSection())

            \(generateGeneralSessionEvents(events, addBreakLinesBool: true))

            \(generateTargetEvents(events, addBreakLinesBool: true))

            \(generateRawEventsTable(events, addBreakLinesBool: true))
        </body>
    <html>
    """

    createFile(fileName: fileName, content: mainContent)
}

// TESTING FUNCTIONS ONLY
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
