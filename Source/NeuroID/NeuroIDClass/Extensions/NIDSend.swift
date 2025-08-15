//
//  NIDSend.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Alamofire
import Foundation

extension NeuroID {
    static func send(
        forceSend: Bool = false,
        eventSubset: [NIDEvent]? = nil,
        completion: @escaping () -> Void = {}
    ) {
        if NeuroID._isTesting {
            return
        }

        if !NeuroID.isStopped() || forceSend {
            DispatchQueue.global(qos: .utility).async {
                NeuroID.shared.payloadSendingService.cleanAndSendEvents(
                    clientKey: NeuroID.getClientKey(),
                    screenName: NeuroID.getScreenName(),
                    onPacketIncrement: { NeuroID.incrementPacketNumber() },
                    onSuccess: completion,
                    onFailure: { error in
                        NeuroID.saveEventToDataStore(
                            NIDEvent.createErrorLogEvent("Group and POST failure: \(error)")
                        )

                        completion()
                    },
                    eventSubset: eventSubset
                )
            }
        }
    }
}
