//
//  NetworkMonitoringService.swift
//  NeuroID
//
//  Created by Kevin Sites on 1/31/24.
//

import Foundation
import Network

protocol NetworkMonitoringServiceProtocol {
    var connectionType: String { get }

    func startMonitoring()
}

enum ConnectionType: String {
    case wifi
    case ethernet
    case cellular
    case unknown
}

class NetworkMonitoringService: NetworkMonitoringServiceProtocol {
    private let queue = DispatchQueue.global()
    private let monitor: NWPathMonitor

    private var noNetworkTask: DispatchWorkItem = DispatchWorkItem {}

    private var resumeNetworkTask: DispatchWorkItem = DispatchWorkItem {}

    private(set) var isConnected: Bool = false
    private(set) var _connectionType: ConnectionType = .unknown
    var connectionType: String {
        _connectionType.rawValue
    }

    init() {
        monitor = NWPathMonitor()
    }

    private func setupNoNetworkTask() {
        noNetworkTask = DispatchWorkItem {
            guard !(self.noNetworkTask.isCancelled) else {
                return
            }

            // pause collection but don't flush events
            NeuroID.pauseCollection(flushEventQueue: false)
        }
    }

    private func setupResumeNetworkTask() {
        resumeNetworkTask = DispatchWorkItem {
            guard !(self.resumeNetworkTask.isCancelled) else {
                return
            }

            NeuroID.resumeCollection()
        }
    }

    func startMonitoring() {
        monitor.start(queue: queue)

        NeuroID.saveEventToLocalDataStore(
            NIDEvent.createInfoLogEvent(
                "Network Monitoring Started with starting status of connectionType:\(connectionType) connected:\(isConnected)"
            )
        )

        monitor.pathUpdateHandler = { path in
            let connectionStatus = path.status == .satisfied

            self.getConnectionType(path)

            NeuroID.saveEventToLocalDataStore(
                NIDEvent(
                    type: .networkState,
                    attrs: [
                        Attrs(n: "connectionType", v: "\(self.connectionType)"),
                    ],
                    iswifi: self._connectionType == .wifi,
                    isconnected: connectionStatus
                )
            )

            if connectionStatus != self.isConnected {
                self.isConnected = connectionStatus
                if !self.isConnected {
                    if !NeuroID.shared.isSDKStarted {
                        return
                    }

                    self.setupNoNetworkTask()
                    DispatchQueue
                        .global(qos: .utility)
                        .asyncAfter(
                            deadline: .now() + 10,
                            execute: self.noNetworkTask
                        )

                } else {
                    self.noNetworkTask.cancel()

                    if NeuroID.shared.isSDKStarted {
                        return
                    }

                    // not collecting but a session is in progress we need to restart
                    if !NeuroID.shared.isSDKStarted,
                       !NeuroID.shared.identifierService.sessionID.isEmptyOrNil
                    {
                        self.setupResumeNetworkTask()

                        DispatchQueue
                            .global(qos: .utility)
                            .asyncAfter(
                                deadline: .now() + 2,
                                execute: self.resumeNetworkTask
                            )
                    }
                }
            }
        }
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    private func getConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            _connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            _connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            _connectionType = .ethernet
        } else {
            _connectionType = .unknown
        }
    }
}
