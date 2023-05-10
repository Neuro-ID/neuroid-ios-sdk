//
//  FileCreationUtils.swift
//  NeuroID
//
//  Created by Kevin Sites on 4/27/23.
//

import Foundation

internal func getFileURL(_ fileName: String?) throws -> URL {
    do {
        var fileURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        if let file = fileName {
            fileURL = fileURL.appendingPathComponent(file)
        }

        return fileURL
    }
    catch {
        // DECIDE HOW TO HANDLE ERRORS?
//        print("Error Generating URL")
    }

    throw NIDError.urlError
}

internal func writeNIDEventsToJSON(_ fileName: String, items: [NIDEvent]) {
    do {
        let fileURL = try getFileURL(fileName)

        let encoder = JSONEncoder()
        try encoder.encode(items).write(to: fileURL)
    }
    catch {
        print(error.localizedDescription)
    }
}

internal func writeDeviceInfoToJSON(_ fileName: String, items: IntegrationHealthDeviceInfo) {
    do {
        let fileURL = try getFileURL(fileName)

        let encoder = JSONEncoder()
        try encoder.encode(items).write(to: fileURL)
    }
    catch {
        print(error.localizedDescription)
    }
}

internal func copyResourceBundleFile(fileName: String, fileDirectory: URL, bundleURL: URL) {
    let fileManager = FileManager.default

    let serverURL = bundleURL.appendingPathComponent(fileName)
    do {
        try fileManager.copyItem(at: serverURL, to: fileDirectory)
    }
    catch let error as NSError {
        if error.code == NSFileWriteFileExistsError {
            try? fileManager.removeItem(at: fileDirectory.appendingPathComponent(fileName))
            try! fileManager.copyItem(at: serverURL, to: fileDirectory.appendingPathComponent(fileName))
        }
        else {
            // DECIDE HOW TO HANDLE ERRORS?
//            print("Error copying file: \(error.localizedDescription)")
        }
    }
}

internal func copyResourceBundleFolder(folderName: String, fileDirectory: URL, bundleURL: URL) {
    let fileManager = FileManager.default

    // CREATE NID FOLDER
    do {
        try fileManager.createDirectory(at: fileDirectory, withIntermediateDirectories: false, attributes: nil)
    }
    catch let error as NSError {
        // DECIDE HOW TO HANDLE ERRORS?
//        print("Error creating directory: \(error.localizedDescription)")
    }

    // copy static files
    let resourcesURL = bundleURL.appendingPathComponent(folderName)
    do {
        try fileManager.copyItem(at: resourcesURL, to: fileDirectory.appendingPathComponent(folderName))
    }
    catch let error as NSError {
        // DECIDE HOW TO HANDLE ERRORS?
//        print("Error copying resources folder: \(error.localizedDescription)")
    }
}
