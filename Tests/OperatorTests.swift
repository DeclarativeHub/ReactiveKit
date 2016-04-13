//
//  OperatorTests.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 12/04/16.
//  Copyright © 2016 Srdan Rasic. All rights reserved.
//

import XCTest
@testable import ReactiveKit

class OperatorsTests: XCTestCase {

  func testBuffer() {
    let stream = Stream.sequence([1,2,3,4,5])
    let buffered = stream.buffer(2)
    buffered.expectNext([[1, 2], [3, 4]])
  }

  // TODO: flatMap

  func testMap() {
    let stream = Stream.sequence([1, 2, 3])
    let mapped = stream.map { $0 * 2 }
    mapped.expectNext([2, 4, 6])
  }

  func testScan() {
    let stream = Stream.sequence([1, 2, 3])
    let scanned = stream.scan(0, +)
    scanned.expectNext([1, 3, 6])
  }

  // TODO: toOperation

  // TODO: toStream

  // TODO: window

  // TODO: debounce

  func testDistinct() {
    let stream = Stream.sequence([1, 2, 2, 3])
    let distinct = stream.distinct()
    distinct.expectNext([1, 2, 3])
  }

  func testElementAt() {
    let stream = Stream.sequence([1, 2, 3])
    let elementAt1 = stream.elementAt(1)
    elementAt1.expectNext([2])
  }

  func testFilter() {
    let stream = Stream.sequence([1, 2, 3])
    let filtered = stream.filter { $0 % 2 != 0 }
    filtered.expectNext([1, 3])
  }

  func testFirst() {
    let stream = Stream.sequence([1, 2, 3])
    let first = stream.first()
    first.expectNext([1])
  }

  func testIgnoreElement() {
    let stream = Stream.sequence([1, 2, 3])
    let ignoreElements = stream.ignoreElements()
    ignoreElements.expectNext([])
  }

  func testLast() {
    let stream = Stream.sequence([1, 2, 3])
    let first = stream.last()
    first.expectNext([3])
  }

  // TODO: sample

  func testSkip() {
    let stream = Stream.sequence([1, 2, 3])
    let skipped1 = stream.skip(1)
    skipped1.expectNext([2, 3])
  }

  func testSkipLast() {
    let stream = Stream.sequence([1, 2, 3])
    let skippedLast1 = stream.skipLast(1)
    skippedLast1.expectNext([1, 2])
  }

  func testTake() {
    let stream = Stream.sequence([1, 2, 3])
    let taken2 = stream.take(2)
    taken2.expectNext([1, 2])
  }

  func testTakeLast() {
    let stream = Stream.sequence([1, 2, 3])
    let takenLast2 = stream.takeLast(2)
    takenLast2.expectNext([2, 3])
  }

  // TODO: throttle

  func testIgnoreNil() {
    let stream = Stream.sequence(Array<Int?>([1, nil, 3]))
    let unwrapped = stream.ignoreNil()
    unwrapped.expectNext([1, 3])
  }

  func testCombineLatestWith() { // TODO: improve
    let streamA = Stream.sequence([1, 2])
    let streamB = Stream.sequence(["A", "B"])
    let combined = streamA.combineLatestWith(streamB).map { "\($0)\($1)" }
    combined.expectNext(["2A", "2B"])
  }

  func testMergeWith() { // TODO: improve
    let streamA = Stream.sequence([1, 2])
    let streamB = Stream.sequence([3, 4])
    let merged = streamA.mergeWith(streamB)
    merged.expectNext([1, 2, 3, 4])
  }

  func testStartWith() {
    let stream = Stream.sequence([1, 2, 3])
    let startWith4 = stream.startWith(4)
    startWith4.expectNext([4, 1, 2, 3])
  }

  func testZipWith() {
    let streamA = Stream.sequence([1, 2, 3])
    let streamB = Stream.sequence(["A", "B"])
    let combined = streamA.zipWith(streamB).map { "\($0)\($1)" }
    combined.expectNext(["1A", "2B"])
  }

  func testConcatWith() { // TODO: improve
    let streamA = Stream.sequence([1, 2])
    let streamB = Stream.sequence([3, 4])
    let merged = streamA.concatWith(streamB)
    merged.expectNext([1, 2, 3, 4])
  }

  // TODO: executeIn

  // TODO: delay

  func testDoOn() {
    let stream = Stream.sequence([1, 2, 3])
    var start = 0
    var next = 0
    var completed = 0
    var disposed = 0
    var terminated = 0

    let d = stream.doOn(next: { _ in next += 1 }, start: { start += 1}, completed: { completed += 1}, disposed: { disposed += 1}, terminated: { terminated += 1 }).observe { _ in }

    XCTAssert(start == 1)
    XCTAssert(next == 3)
    XCTAssert(completed == 1)
    XCTAssert(disposed == 0)
    XCTAssert(terminated == 1)

    d.dispose()
    XCTAssert(disposed == 1)
  }

  // TODO: observeIn
  func testPausable() {
    let stream = PushStream<Int>()
    let controller = PushStream<Bool>()
    let paused = stream.shareReplay().pausable(by: controller)
    paused.expectNext([4, 1, 2, 3])
  }

}

extension StreamType {

  func expectNext(expectedElements: [Element], @autoclosure _ message: () -> String = "", file: StaticString = #file, line: UInt = #line) {
    expect(expectedElements.map { StreamEvent.Next($0) } + [StreamEvent.Completed], message, file: file, line: line)
  }

  func expect(expectedEvents: [StreamEvent<Element>], @autoclosure _ message: () -> String = "", file: StaticString = #file, line: UInt = #line) {
    var eventsToProcess = expectedEvents
    var receivedEvents: [StreamEvent<Element>] = []
    let message = message()
    let _ = observe { event in
      receivedEvents.append(event)
      if expectedEvents.count == 0 {
        XCTFail("Got more events then expected. Unexpected event: \(event)")
        return
      }
      let expected = eventsToProcess.removeFirst()
      XCTAssert(event.isEqualTo(expected), message + "(Got \(receivedEvents) instead of \(expectedEvents))", file: file, line: line)
    }
  }
}

extension StreamEventType {

  func isEqualTo<E: StreamEventType where E.Element == Element>(event: E) -> Bool {

    if self.isCompletion && event.isCompletion {
      return true
    } else if let left = self.element, right = event.element {
      if let left = left as? Int, right = right as? Int {
        return left == right
      } else if let left = left as? [Int], right = right as? [Int] {
        return left == right
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


