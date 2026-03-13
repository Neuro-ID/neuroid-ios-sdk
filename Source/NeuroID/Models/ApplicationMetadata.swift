//
//  ApplicationMetadata.swift
//  NeuroID
//
//  Created by Kevin Sites on 7/23/24.
//

import Foundation

struct ApplicationMetadata {
    // CFBundleShortVersionString - The release version number string (e.g., "1.0.0")
    let versionName: String

    // CFBundleVersion - The build version number string (e.g., "1")
    let versionNumber: String

    // CFBundleIdentifier - The bundle identifier (e.g., "com.company.app"), falls back to CFBundleName if identifier is empty
    let packageName: String

    // CFBundleName - The user-visible short name for the bundle
    let applicationName: String
    
    // React Native version, empty string for native iOS apps
    let rnVersion: String

    // MinimumOSVersion - The minimum iOS version required for the app to run (from Info.plist)
    let minOSVersion: String
}
