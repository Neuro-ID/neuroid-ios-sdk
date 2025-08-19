//
//  NIDSend.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Alamofire
import Foundation

extension NeuroID {
    func send(
        forceSend: Bool = false,
        eventSubset: [NIDEvent]? = nil,
        completion: @escaping () -> Void = {}
    ) {
        if NeuroID._isTesting {
            return
        }

        if !self.isStopped() || forceSend {
            DispatchQueue.global(qos: .utility).async {
                self.payloadSendingService.cleanAndSendEvents(
                    clientKey: self.getClientKey(),
                    screenName: self.getScreenName(),
                    onPacketIncrement: { self.incrementPacketNumber() },
                    onSuccess: completion,
                    onFailure: { error in
                        self.saveEventToDataStore(
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
