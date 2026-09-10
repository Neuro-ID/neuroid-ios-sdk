//
//  SessionObserverProtocol.swift
//  NeuroID
//

import Foundation

protocol SessionObserver: Sendable {
    func start() async
    func stop() async
}
