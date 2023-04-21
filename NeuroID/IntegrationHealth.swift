//
//  IntegrationHealth.swift
//  NeuroID
//
//  Created by Kevin Sites on 4/20/23.
//

import Foundation

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

func formatEventRows(events: [NIDEvent], rowFormatFn: (_: NIDEvent, _: Double) -> String) -> String {
    var eventContent = ""
    var eventCount: Double = 0
    for event in events {
        let row = rowFormatFn(event, eventCount)
        eventContent += row

        eventCount += 1
    }

    return eventContent
}

func generateGeneralSessionEvents(events: [NIDEvent]) -> String {
    var eventContent = formatEventRows(events: events) { event, eventCount in
        """
            <tr>
                <td>\(event.type)</td>
                <td>\(formatDate(date: Date() + eventCount))</td>
                <td></td>
            </tr>
        """
    }

    return generateHTMLTable(tableName: "General Session Markers", columns: ["Event Type", "Timestamp", "Additional"], tableContent: eventContent)
}

func generateTargetEvents(events: [NIDEvent]) -> String {
//    var targetDict: [String: [NIDEvent]] = [:]
//
//    for e in events {
//        let eDict = e.asDictionary
//        let targetName = (eDict["tgs"] ?? "n/a" as String) as! String
//
//        if targetDict[targetName] != nil {
//            targetDict[targetName]?.append(e)
//        }
//        else {
//            targetDict[targetName] = [e]
//        }
//    }

    var eventContent = formatEventRows(events: events) { event, eventCount in
        let eDict = event.asDictionary
        let targetName = (eDict["tgs"] ?? "n/a" as String) as! String

        return
            """
                <tr>
                    <td>\(targetName)</td>
                    <td>\(event.type)</td>
                    <td>\(formatDate(date: Date() + eventCount))</td>
                </tr>
            """
    }

    return generateHTMLTable(tableName: "Target Events", columns: ["Target", "Event Type", "Observed"], tableContent: eventContent)
}

public enum IntegrationHealth {
    static func generateIntegrationHealthReport() {
        let events = NeuroID.getIntegrationHealthEvents()
        //    let events: [NIDEvent] = [generateEvent(), generateEvent(NIDEventName.input), generateEvent(NIDEventName.textChange), generateEvent(NIDEventName.registerTarget), generateEvent(NIDEventName.applicationSubmit), generateEvent(NIDEventName.createSession)]

        let fileName = "\(formatDate(date: Date()))-integration.html"

        let mainContent = """
        <html>
            \(generateHTMLHeader(tables: ["General Session Markers", "Target Events"]))
            <body style="max-width: 92%; margin: 0px 2%">
                </br>
                <h1>Integration Health Report</h1>
                <p>SDK Version: \(NeuroID.getSDKVersion() ?? "1.0.0")</p>
                </br>

                \(generateGeneralSessionEvents(events: events))

                </br>
                </br>
                \(generateTargetEvents(events: events))
            </body>
        <html>
        """

        createFile(fileName: fileName, content: mainContent)
    }
}

// func generateEvent(_ eventType: NIDEventName = NIDEventName.textChange) -> NIDEvent {
//    let textControl = UITextField()
//    textControl.text = "test Text"
//
//    let textValue = textControl.text ?? ""
//    let lengthValue = "S~C~~\(textControl.text?.count ?? 0)"
//
//    // Text Change
//    let textChangeTG = ["tgs": TargetValue.string("id")]
//    let textChangeEvent = NIDEvent(type: eventType, tg: textChangeTG)
//
//    return textChangeEvent
// }
