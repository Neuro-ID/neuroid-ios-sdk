//
//  JobManagerService.swift
//  NeuroID
//
//  Created by Kevin Sites on 8/11/25.
//

protocol JobManagerServiceProtocol {
    func startJobs()
    func stopJobs()
}

class JobManagerService: JobManagerServiceProtocol {
    let payloadSendingService: PayloadSendingServiceProtocol
    let configService: ConfigServiceProtocol

    var eventCollectionSendJob: RepeatingTaskProtocol
    var gyroAccelCollectionSendJob: RepeatingTaskProtocol

//    // adding these tasks here to be able to inject them for tests
//    lazy var eventCollectionTask: () -> Void = { [unowned self] in
//        if !NeuroID.isStopped() {
//            self.payloadSendingService.send()
//        }
//    }
//
//    lazy var gyroAccelCollectionTask: () -> Void = { [unowned self] in
//        if !NeuroID.isStopped() {
//            NeuroID.saveEventToLocalDataStore(
//                NIDEvent(
//                    type: .cadenceReadingAccel,
//                    attrs: [
//                        Attrs(
//                            n: "interval",
//                            v: "\(self.configService.configCache.gyroAccelCadenceTime)ms"
//                        ),
//                    ]
//                )
//            )
//        }
//    }

    init(
        payloadSendingService: PayloadSendingServiceProtocol,
        configService: ConfigServiceProtocol,

        eventCollectionSendJob: RepeatingTaskProtocol,
        gyroAccelCollectionSendJob: RepeatingTaskProtocol

//        eventCollectionTask: @escaping () -> Void,
//        gyroAccelCollectionTask: @escaping () -> Void
    ) {
        self.eventCollectionSendJob = eventCollectionSendJob
        self.gyroAccelCollectionSendJob = gyroAccelCollectionSendJob

        self.payloadSendingService = payloadSendingService
        self.configService = configService
//        self.eventCollectionTask = eventCollectionTask
//        self.gyroAccelCollectionTask = gyroAccelCollectionTask
    }

    func createEventCollectionSendJob() {}

    func startJobs() {
//        if let eventCollectionJob = eventCollectionSendJob {
//            eventCollectionJob.cancel()
//            eventCollectionSendJob = nil
//        }
//
//        if let gyroAccelCollectionJob = gyroAccelCollectionSendJob {
//            gyroAccelCollectionJob.cancel()
//            gyroAccelCollectionSendJob = nil
//        }

        eventCollectionSendJob.start()
        gyroAccelCollectionSendJob.start()
    }

    func stopJobs() {
        eventCollectionSendJob.cancel()
        gyroAccelCollectionSendJob.cancel()
    }
}
