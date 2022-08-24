//
//  MetadataEngine.swift
//  NeuroID
//
//  Created by Clayton Selby on 8/23/22.
//

import Foundation
import SwiftUI

public class MetadataEngine {
    static func isCydiaAppInstalled() -> Bool {
        return UIApplication.shared.canOpenURL(URL(string: "cydia://")!)
    }
}


