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
        print("Error Generating URL")
    }

    throw NIDError.urlError
}

func writeNIDEventsToJSON(_ fileName: String, items: [NIDEvent]) {
    do {
        let fileURL = try getFileURL(fileName)

        let encoder = JSONEncoder()
        try encoder.encode(items).write(to: fileURL)
    }
    catch {
        print(error.localizedDescription)
    }
}

func writeDeviceInfoToJSON(_ fileName: String, items: IntegrationHealthDeviceInfo) {
    do {
        let fileURL = try getFileURL(fileName)

        let encoder = JSONEncoder()
        try encoder.encode(items).write(to: fileURL)
    }
    catch {
        print(error.localizedDescription)
    }
}

//
// func copyFilesFromBundleToDocumentsFolderWith(fileExtension: String) {
//    if let resPath = Bundle.main.resourcePath {
//        do {
//            let dirContents = try FileManager.default.contentsOfDirectory(atPath: resPath)
//            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
//
//            print("res: \(resPath)")
//            let filteredFiles = dirContents.filter { $0.contains(fileExtension) }
//
//            print("coppying: \(filteredFiles.count)")
//            for fileName in filteredFiles {
//                print("FILE: \(fileName)")
//                if let documentsURL = documentsURL {
//                    let sourceURL = Bundle.main.bundleURL.appendingPathComponent(fileName)
//                    let destURL = documentsURL.appendingPathComponent(fileName)
//                    do { try FileManager.default.copyItem(at: sourceURL, to: destURL) } catch {}
//                }
//            }
//        }
//        catch {}
//    }
// }
//
// func copyFolders() {
//    let fileManager = FileManager.default
//
//    let documentsUrl = fileManager.urls(for: .documentDirectory,
//                                        in: .userDomainMask)
//
//    guard documentsUrl.count != 0 else {
//        print("NO DOCS")
//        return // Could not find documents URL
//    }
//
//    let finalDatabaseURL = documentsUrl.first!.appendingPathComponent("IntegrationHealthStatic")
//
//    if !((try? finalDatabaseURL.checkResourceIsReachable()) ?? false) {
//        print("DB does not exist in documents folder")
//
//        let documentsURL = Bundle.main.resourceURL?.appendingPathComponent("IntegrationHealthStatic")
//
//        print(documentsURL)
//        do {
//            if !FileManager.default.fileExists(atPath: finalDatabaseURL.path) {
//                try FileManager.default.createDirectory(atPath: finalDatabaseURL.path, withIntermediateDirectories: false, attributes: nil)
//            }
//            copyFiles(pathFromBundle: (documentsURL?.path)!, pathDestDocs: finalDatabaseURL.path)
//        }
//        catch let error as NSError {
//            print("Couldn't copy file to final location! Error:\(error.description)")
//        }
//    }
//    else {
//        print("Database file found at path: \(finalDatabaseURL.path)")
//    }
// }
//
// func copyFiles(pathFromBundle: String, pathDestDocs: String) {
//    let fileManagerIs = FileManager.default
//    do {
//        print("trying to print \(pathFromBundle)")
//        let filelist = try fileManagerIs.contentsOfDirectory(atPath: pathFromBundle)
//        try? fileManagerIs.copyItem(atPath: pathFromBundle, toPath: pathDestDocs)
//
//        print("COPYING \(filelist.count) FIles")
//
//        for filename in filelist {
//            print("COPYING: \(filename)")
//            try? fileManagerIs.copyItem(atPath: "\(pathFromBundle)/\(filename)", toPath: "\(pathDestDocs)/\(filename)")
//        }
//    }
//    catch {
//        print("\nError: \(error)\n")
//    }
// }

/// OLD
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
