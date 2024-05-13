//
//  FileCreationUtils.swift
//  NeuroID
//
//  Created by Kevin Sites on 4/27/23.
//

import Foundation

func getFileURL(_ fileName: String?) throws -> URL {
    do {
        var fileURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        if let file = fileName {
            fileURL = fileURL.appendingPathComponent(file)
        }

        return fileURL
    }
    catch {
        NIDLog.e("Error Retrieving the FileURL: \(fileName ?? "") - \(error.localizedDescription)")
        throw error
    }
}

func writeNIDEventsToJSON(_ fileName: String, items: [NIDEvent]) throws {
    do {
        let fileURL = try getFileURL(fileName)

        let encoder = JSONEncoder()
        try encoder.encode(items).write(to: fileURL)
    }
    catch {
        NIDLog.e("Error Writing to File: \(fileName) - \(error.localizedDescription)")
        throw error
    }
}

func writeDeviceInfoToJSON(_ fileName: String, items: IntegrationHealthDeviceInfo) throws {
    do {
        let fileURL = try getFileURL(fileName)

        let encoder = JSONEncoder()
        try encoder.encode(items).write(to: fileURL)
    }
    catch {
        NIDLog.e("Error Writing to File: \(fileName) - \(error.localizedDescription)")
        throw error
    }
}

func copyResourceBundleFile(fileName: String, fileDirectory: URL, bundleURL: URL) throws {
    let fileManager = FileManager.default

//    checkAndDeleteItems(fileDirectory: fileDirectory)

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
            NIDLog.e("Error Copying Resource: \(fileName) - \(error.localizedDescription)")
            throw error
        }
    }
}

func copyResourceBundleFolder(folderName: String, fileDirectory: URL, bundleURL: URL) throws {
    let fileManager = FileManager.default

    checkAndDeleteItems(fileDirectory: fileDirectory)

    // CREATE NID FOLDER
    do {
        try fileManager.createDirectory(at: fileDirectory, withIntermediateDirectories: false, attributes: nil)
    }
    catch let error as NSError {
        NIDLog.e("Error Copying Resource Directory: \(folderName) - \(error.localizedDescription)")
        throw error
    }

    // copy static files
    let resourcesURL = bundleURL.appendingPathComponent(folderName)
    do {
        try fileManager.copyItem(at: resourcesURL, to: fileDirectory.appendingPathComponent(folderName))
    }
    catch let error as NSError {
        NIDLog.e("Error Copying Resource Directory: \(resourcesURL) - \(error.localizedDescription)")
        throw error
    }
}

func checkAndDeleteItems(fileDirectory: URL) {
    let fileManager = FileManager.default

    // Check if the folder exists
    if fileManager.fileExists(atPath: fileDirectory.path) {
        do {
            // Delete the folder and all its contents
            try fileManager.removeItem(at: fileDirectory)
        }
        catch {
            // Handle the error if something goes wrong during the deletion
            NIDLog.e("Error Removing Folder: \(error)")
        }
    }
}
