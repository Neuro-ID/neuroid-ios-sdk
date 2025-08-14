//
//  RepeatingTask.swift
//  NeuroID
//
//  Created by Kevin Sites on 8/11/25.
//
import Foundation

protocol RepeatingTaskProtocol {
    func start()
    func cancel()
}

class RepeatingTask: RepeatingTaskProtocol {
    private var workItem: DispatchWorkItem?
    private let interval: TimeInterval
    private let queue: DispatchQueue
    private let task: () -> Void

    init(
        interval: TimeInterval,
        queue: DispatchQueue = .global(qos: .utility),
        task: @escaping () -> Void
    ) {
        self.interval = interval
        self.queue = queue
        self.task = task
    }

    func start() {
        cancel() // Cancel any existing task
        scheduleNext()
    }

    func cancel() {
        workItem?.cancel()
        workItem = nil
    }

    private func scheduleNext() {
        workItem = DispatchWorkItem { [weak self] in
            guard let self = self, !(self.workItem?.isCancelled ?? true) else { return }
            self.task()
            self.scheduleNext()
        }

        queue.asyncAfter(deadline: .now() + interval, execute: workItem!)
    }
}
