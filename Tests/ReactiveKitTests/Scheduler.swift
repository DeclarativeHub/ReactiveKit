//
//  Scheduler.swift
//  ReactiveKit-Tests
//
//  Created by Srdan Rasic on 01/01/2020.
//  Copyright © 2020 DeclarativeHub. All rights reserved.
//

import Foundation
import ReactiveKit

/// A scheduler that buffers actions and enables their manual execution through `run` methods.
class Scheduler: ReactiveKit.Scheduler {

    private var availableRuns = 0
    private var scheduledBlocks: [() -> Void] = []
    private(set) var numberOfRuns = 0

    func schedule(_ action: @escaping () -> Void) {
        scheduledBlocks.append(action)
        tryRun()
    }

    func runOne() {
        guard availableRuns < Int.max else { return }
        availableRuns += 1
        tryRun()
    }

    func runRemaining() {
        availableRuns = Int.max
        tryRun()
    }

    private func tryRun() {
        while availableRuns > 0 && scheduledBlocks.count > 0 {
            let block = scheduledBlocks.removeFirst()
            block()
            numberOfRuns += 1
            availableRuns -= 1
        }
    }
}
