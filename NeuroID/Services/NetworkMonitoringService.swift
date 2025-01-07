//
//  NetworkMonitoringService.swift
//  NeuroID
//
//  Created by Kevin Sites on 1/31/24.
//

import Foundation
import Network

class NetworkMonitoringService {
    private let queue = DispatchQueue.global()
    private let monitor: NWPathMonitor

    private var noNetworkTask: DispatchWorkItem = DispatchWorkItem {}

    private var resumeNetworkTask: DispatchWorkItem = DispatchWorkItem {}

    private(set) var isConnected: Bool = false
    private(set) var connectionType: ConnectionType = .unknown

    enum ConnectionType: String {
        case wifi
        case cellular
        case ethernet
        case unknown
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
            NIDEvent(type: .log, level: "info", m: "Network Monitoring Started with starting status of connectionType:\(connectionType) connected:\(isConnected)")
        )

        monitor.pathUpdateHandler = { path in
            let connectionStatus = path.status == .satisfied

            self.getConnectionType(path)

            let nidEvent = NIDEvent(type: .networkState)
            nidEvent.iswifi = self.connectionType == .wifi
            nidEvent.isconnected = connectionStatus
            nidEvent.attrs = [
                Attrs(n: "connectionType", v: "\(self.connectionType.rawValue)"),
            ]

            NeuroID.saveEventToLocalDataStore(nidEvent)

            if connectionStatus != self.isConnected {
                self.isConnected = connectionStatus
                if !self.isConnected {
                    if !NeuroID.isSDKStarted {
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

                    if NeuroID.isSDKStarted {
                        return
                    }

                    // not collecting but a session is in progress we need to restart
                    if !NeuroID.isSDKStarted, (NeuroID.sessionID?.isEmpty) != nil {
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
