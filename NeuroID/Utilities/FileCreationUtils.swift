//
//  FileCreationUtils.swift
//  NeuroID
//
//  Created by Kevin Sites on 4/27/23.
//

import Foundation

func writeNIDEventsToJSON(_ fileName: String, items: [NIDEvent]) {
    do {
        let fileURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("\("nid.local")/\(fileName)")

        print("***** file URl \(fileURL)")

        let encoder = JSONEncoder()
        try encoder.encode(items).write(to: fileURL)
    }
    catch {
        print("***** ERRRR")
        print(error.localizedDescription)
    }
}

func saveToJsonFile(fileName: String, JSONData: [Any]) {
    // Get the url of Persons.json in document directory
    guard let documentDirectoryUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
    let fileUrl = documentDirectoryUrl.appendingPathComponent(fileName)
//

    let fileMang = FileManager.default
    print("Saving Integration Health Events at: \(fileUrl)")
    if fileMang.fileExists(atPath: fileUrl.path) {
        do {
            try fileMang.removeItem(atPath: fileUrl.path)
        }
        catch {}
    }

    // Transform array into data and save it into file
    do {
        print("**************TRY CONVERTING \(JSONData)")
        let data = try JSONSerialization.data(withJSONObject: JSONData, options: [])
        print("**************TRY SAVING")
        try data.write(to: fileUrl, options: [])
    }
    catch let error as NSError {
        print("Array to JSON conversion failed: \(error.localizedDescription)")
    }
    catch {
        print("****ERRROR \(error)")
    }
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
