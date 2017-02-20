//
//  Common.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 14/04/16.
//  Copyright © 2016 Srdan Rasic. All rights reserved.
//

import XCTest
import ReactiveKit

func dumpEquality<T>(lhs: T, rhs: T) -> Bool {
  var (lhsDump, rhsDump) = ("", "")
  dump(lhs, to: &lhsDump)
  dump(rhs, to: &rhsDump)
  return lhsDump == rhsDump
}

extension Event {

  func isEqualTo(_ event: Event<Element, Error>) -> Bool {

    switch (self, event) {
    case (.completed, .completed):
      return true
    case (.failed, .failed):
      return true
    case (.next(let left), .next(let right)):
      return dumpEquality(lhs: left, rhs: right)
    default:
        return false
    }
  }
}

extension SignalProtocol {
  
  // Synchronous test
  func expectComplete(after expectedElements: [Element],
                      file: StaticString = #file, line: UInt = #line) {
    expect(events: expectedElements.map { .next($0) } + [.completed], file: file, line: line)
  }

  func expect(events expectedEvents: [Event<Element, Error>],
              file: StaticString = #file, line: UInt = #line) {
    var eventsToProcess = expectedEvents
    var receivedEvents: [Event<Element, Error>] = []
    var matchedAll = false
    let _ = observe { event in
      receivedEvents.append(event)
      if eventsToProcess.count == 0 {
        XCTFail("Got more events than expected.")
        return
      }
      let expected = eventsToProcess.removeFirst()
      XCTAssert(event.isEqualTo(expected), "(Got \(receivedEvents) instead of \(expectedEvents))", file: file, line: line)
      if eventsToProcess.count == 0 {
        matchedAll = true
      }
    }
    if !matchedAll {
      XCTFail("Got only first \(receivedEvents.count) events of expected \(expectedEvents))", file: file, line: line)
    }
  }
  
  func expectNoEvent(file: StaticString = #file, line: UInt = #line) {
    let _ = observe { event in
      XCTFail("Got a \(event) when expected empty", file: file, line: line)
    }
  }
  
  // Asynchronous test
  func expectAsyncComplete(after expectedElements: [Element],
                           expectation: XCTestExpectation,
                           file: StaticString = #file, line: UInt = #line) {
    expectAsync(events: expectedElements.map { .next($0) } + [.completed], expectation: expectation, file: file, line: line)
  }
  
  func expectAsync(events expectedEvents: [Event<Element, Error>],
                   expectation: XCTestExpectation,
                   file: StaticString = #file, line: UInt = #line) {
    XCTAssert(!expectedEvents.isEmpty, "Use expectEmptyAsync for waiting empty signal")
    var eventsToProcess = expectedEvents
    var receivedEvents: [Event<Element, Error>] = []
    let _ = observe { event in
      receivedEvents.append(event)
      if eventsToProcess.count == 0 {
        XCTFail("Got more events than expected.")
        return
      }
      let expected = eventsToProcess.removeFirst()
      XCTAssert(event.isEqualTo(expected), "(Got \(receivedEvents) instead of \(expectedEvents))", file: file, line: line)
      if eventsToProcess.count == 0 {
        expectation.fulfill()
      }
    }
  }
}

class Scheduler {
  private var availableRuns = 0
  private var scheduledBlocks: [() -> Void] = []
  private(set) var numberOfRuns = 0

  func context(_ block: @escaping () -> Void) {
    self.scheduledBlocks.append(block)
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

