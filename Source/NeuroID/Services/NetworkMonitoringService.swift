//
//  NetworkMonitoringService.swift
//  NeuroID
//
//  Created by Kevin Sites on 1/31/24.
//

import Foundation
import Network

protocol NetworkMonitoringServiceProtocol {
    var connectionType: ConnectionType { get }

    func start()
    func stop()
}

enum ConnectionType: String {
    case wifi
    case ethernet
    case cellular
    case unknown
}

class NetworkMonitoringService: NetworkMonitoringServiceProtocol {
    let eventService: EventStorageServiceProtocol

    private let queue = DispatchQueue.global()
    private let monitor: NWPathMonitor

    private(set) var isMonitoring: Bool = false
    private(set) var connectionType: ConnectionType = .unknown

    init(eventService: EventStorageServiceProtocol) {
        monitor = NWPathMonitor()
        self.eventService = eventService
    }

    func start() {
        guard !isMonitoring else { return }

        NeuroIDCore.shared.saveEventToLocalDataStore(
            NIDEvent.createInfoLogEvent(
                "Network Monitoring Started with starting status of connectionType:\(connectionType)"
            )
        )

        monitor.pathUpdateHandler = { path in

            let connectionStatus = path.status == .satisfied
            let connectionType = self.connectionType(for: path)

            self.setConnectionType(connectionType)

            NeuroIDCore.shared.saveEventToLocalDataStore(
                NIDEvent(
                    type: .networkState,
                    attrs: [
                        Attrs(n: "connectionType", v: "\(self.connectionType)")
                    ],
                    iswifi: self.connectionType == .wifi,
                    isconnected: connectionStatus
                )
            )
        }
        monitor.start(queue: queue)
        isMonitoring = true
    }

    func stop() {
        guard isMonitoring else { return }
        isMonitoring = false
        monitor.cancel()
    }

    private func connectionType(for path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .ethernet }
        return .unknown
    }

    func setConnectionType(_ type: ConnectionType) {
        self.connectionType = type
    }
}
