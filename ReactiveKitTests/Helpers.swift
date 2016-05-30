//
//  Common.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 14/04/16.
//  Copyright © 2016 Srdan Rasic. All rights reserved.
//

import XCTest
@testable import ReactiveKit

extension EventType {

  func isEqualTo<E: EventType where E.Element == Element>(event: E) -> Bool {

    if self.isCompletion && event.isCompletion {
      return true
    } else if self.isFailure && event.isFailure {
      return true
    } else if let left = self.element, right = event.element {
      if let left = left as? Int, right = right as? Int {
        return left == right
      } else if let left = left as? [Int], right = right as? [Int] {
        return left == right
      } else if let left = left as? (Int?, Int), right = right as? (Int?, Int) {
        return left.0 == right.0 && left.1 == right.1
      } else if let left = left as? String, right = right as? String {
        return left == right
      } else if let left = left as? [String], right = right as? [String] {
        return left == right
      } else {
        fatalError("Cannot compare that element type.")
      }
    } else {
      return false
    }
  }
}

extension _StreamType {

  func expectNext(expectedElements: [Event.Element], @autoclosure _ message: () -> String = "", expectation: XCTestExpectation? = nil, file: StaticString = #file, line: UInt = #line) {
    expect(expectedElements.map { Event.next($0) } + [Event.completed()], message, expectation: expectation, file: file, line: line)
  }

  func expect(expectedEvents: [Event], @autoclosure _ message: () -> String = "", expectation: XCTestExpectation? = nil, file: StaticString = #file, line: UInt = #line) {
    var eventsToProcess = expectedEvents
    var receivedEvents: [Event] = []
    let message = message()
    let _ = observe { event in
      receivedEvents.append(event)
      if eventsToProcess.count == 0 {
        XCTFail("Got more events then expected.")
        return
      }
      let expected = eventsToProcess.removeFirst()
      XCTAssert(event.isEqualTo(expected), message + "(Got \(receivedEvents) instead of \(expectedEvents))", file: file, line: line)
      if event.isTermination {
        expectation?.fulfill()
      }
    }
  }
}

class Scheduler {
  private var availableRuns = 0
  private var scheduledBlocks: [() -> Void] = []
  private(set) var numberOfRuns = 0

  func context(block: () -> Void) {
    self.scheduledBlocks.append(block)
    tryRun()
  }

  func runOne() {
    guard availableRuns < Int.max else { return }
    availableRuns += 1
    tryRun()
  }

  func runRemaining() {
    availableRuns += Int.max
    tryRun()
  }

  private func tryRun() {
    while  availableRuns > 0 && scheduledBlocks.count > 0 {
      let block = scheduledBlocks.removeFirst()
      block()
      numberOfRuns += 1
      availableRuns -= 1
    }
  }
}
