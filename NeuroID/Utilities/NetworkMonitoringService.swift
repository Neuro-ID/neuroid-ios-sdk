//
//  NetworkMonitoringService.swift
//  NeuroID
//
//  Created by Kevin Sites on 1/31/24.
//

import Foundation
import Network

internal class NetworkMonitoringService {
    private let queue = DispatchQueue.global()
    private let monitor: NWPathMonitor

    internal private(set) var isConnected: Bool = false
    internal private(set) var connectionType: ConnectionType = .unknown

    enum ConnectionType: String {
        case wifi
        case cellular
        case ethernet
        case unknown
    }

    init() {
        monitor = NWPathMonitor()
    }

    internal func startMonitoring() {
        monitor.start(queue: queue)

        monitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            self.getConnectionType(path)

            let nidEvent = NIDEvent(type: .networkState)
            nidEvent.iswifi = self.connectionType == .wifi
            nidEvent.isconnected = self.isConnected
            nidEvent.attrs = [
                Attrs(n: "connectionType", v: "\(self.connectionType.rawValue)")
            ]

            NeuroID.saveEventToLocalDataStore(nidEvent)
        }
    }

    internal func stopMonitoring() {
        monitor.cancel()
    }

    private func getConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
    }
}
