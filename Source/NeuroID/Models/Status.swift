//
//  Status.swift
//  NeuroID
//
//  Created by Collin Dunphy on 9/8/26.
//

import Foundation

enum ConfigurationStatus {
    case notConfigured, configured
}

public enum CollectionStatus: Sendable {
    case running, paused, stopped
}
