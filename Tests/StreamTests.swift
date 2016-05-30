//
//  OperatorTests.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 12/04/16.
//  Copyright © 2016 Srdan Rasic. All rights reserved.
//

import XCTest
@testable import ReactiveKit

class StreamTests: XCTestCase {

  func testProductionAndObservation() {
    let bob = Scheduler()
    bob.runRemaining()

    let stream = Stream.sequence([1, 2, 3]).executeIn(bob.context)

    stream.expectNext([1, 2, 3])
    stream.expectNext([1, 2, 3])
    XCTAssertEqual(bob.numberOfRuns, 2)
  }

  func testDisposing() {
    let disposable = SimpleDisposable()

    let stream = Stream<Int> { _ in
      return disposable
    }

    stream.observe { _ in }.dispose()
    XCTAssertTrue(disposable.isDisposed)
  }

  func testJust() {
    let stream = Stream.just(1)
    stream.expectNext([1])
  }

  func testSequence() {
    let stream = Stream.sequence([1, 2, 3])
    stream.expectNext([1, 2, 3])
  }

  func testCompleted() {
    let stream = Stream<Int>.completed()
    stream.expectNext([])
  }

  func testNever() {
    let stream = Stream<Int>.never()
    stream.expectNext([])
  }

  func testBuffer() {
    let stream = Stream.sequence([1,2,3,4,5])
    let buffered = stream.buffer(2)
    buffered.expectNext([[1, 2], [3, 4]])
  }

  func testMap() {
    let stream = Stream.sequence([1, 2, 3])
    let mapped = stream.map { $0 * 2 }
    mapped.expectNext([2, 4, 6])
  }

  func testScan() {
    let stream = Stream.sequence([1, 2, 3])
    let scanned = stream.scan(0, +)
    scanned.expectNext([0, 1, 3, 6])
  }

  func testToOperation() {
    let stream = Stream.sequence([1, 2, 3])
    let operation = stream.toOperation() as Operation<Int, NSError>
    operation.expectNext([1, 2, 3])
  }

  func testToStream() {
    let stream = Stream.sequence([1, 2, 3])
    let stream2 = stream.toStream()
    stream2.expectNext([1, 2, 3])
  }

  func testWindow() {
    let stream = Stream.sequence([1, 2, 3])
    let window = stream.window(2)
    window.merge().expectNext([1, 2])
  }

  func testDebounce() {
    let stream = Stream<Int>.interval(0.1, queue: Queue.global).take(3)
    let distinct = stream.debounce(0.2, on: Queue.global)
    let expectation = expectationWithDescription("completed")
    distinct.expectNext([2], expectation: expectation)
    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testDistinct() {
    let stream = Stream.sequence([1, 2, 2, 3])
    let distinct = stream.distinct { a, b in a != b }
    distinct.expectNext([1, 2, 3])
  }

  func testDistinct2() {
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

  func testThrottle() {
    let stream = Stream<Int>.interval(0.4, queue: Queue.global).take(5)
    let distinct = stream.throttle(1)
    let expectation = expectationWithDescription("completed")
    distinct.expectNext([0, 3], expectation: expectation)
    waitForExpectationsWithTimeout(3, handler: nil)
  }

  func testIgnoreNil() {
    let stream = Stream.sequence(Array<Int?>([1, nil, 3]))
    let unwrapped = stream.ignoreNil()
    unwrapped.expectNext([1, 3])
  }

  func testCombineLatestWith() {
    let bob = Scheduler()
    let eve = Scheduler()

    let streamA = Stream.sequence([1, 2, 3]).observeIn(bob.context)
    let streamB = Stream.sequence(["A", "B", "C"]).observeIn(eve.context)
    let combined = streamA.combineLatestWith(streamB).map { "\($0)\($1)" }

    let expectation = expectationWithDescription("completed")
    combined.expectNext(["1A", "1B", "2B", "3B", "3C"], expectation: expectation)

    bob.runOne()
    eve.runOne()
    eve.runOne()
    bob.runRemaining()
    eve.runRemaining()

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testMergeWith() {
    let bob = Scheduler()
    let eve = Scheduler()
    let streamA = Stream.sequence([1, 2, 3]).observeIn(bob.context)
    let streamB = Stream.sequence([4, 5, 6]).observeIn(eve.context)
    let merged = streamA.mergeWith(streamB)

    let expectation = expectationWithDescription("completed")
    merged.expectNext([1, 4, 5, 2, 6, 3], expectation: expectation)

    bob.runOne()
    eve.runOne()
    eve.runOne()
    bob.runOne()
    eve.runRemaining()
    bob.runRemaining()

    waitForExpectationsWithTimeout(1, handler: nil)
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

  func testExecuteIn() {
    let bob = Scheduler()
    bob.runRemaining()

    let stream = Stream.sequence([1, 2, 3]).executeIn(bob.context)
    stream.expectNext([1, 2, 3])

    XCTAssertEqual(bob.numberOfRuns, 1)
  }

  // TODO: delay

  func testDoOn() {
    let stream = Stream.sequence([1, 2, 3])
    var start = 0
    var next = 0
    var completed = 0
    var disposed = 0

    let d = stream.doOn(next: { _ in next += 1 }, start: { start += 1}, completed: { completed += 1}, disposed: { disposed += 1}).observe { _ in }

    XCTAssert(start == 1)
    XCTAssert(next == 3)
    XCTAssert(completed == 1)
    XCTAssert(disposed == 1)

    d.dispose()
    XCTAssert(disposed == 1)
  }

  func testObserveIn() {
    let bob = Scheduler()
    bob.runRemaining()

    let stream = Stream.sequence([1, 2, 3]).observeIn(bob.context)
    stream.expectNext([1, 2, 3])

    XCTAssertEqual(bob.numberOfRuns, 4) // 3 elements + completion
  }

  func testPausable() {
    let stream = PushStream<Int>()
    let controller = PushStream<Bool>()
    let paused = stream.shareReplay().pausable(by: controller)

    let expectation = expectationWithDescription("completed")
    paused.expectNext([1, 3], expectation: expectation)

    stream.next(1)
    controller.next(false)
    stream.next(2)
    controller.next(true)
    stream.next(3)
    stream.completed()

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testAmbWith() {
    let bob = Scheduler()
    let eve = Scheduler()

    let streamA = Stream.sequence([1, 2]).observeIn(bob.context)
    let streamB = Stream.sequence([3, 4]).observeIn(eve.context)
    let ambdWith = streamA.ambWith(streamB)

    let expectation = expectationWithDescription("completed")
    ambdWith.expectNext([3, 4], expectation: expectation)

    eve.runOne()
    bob.runRemaining()
    eve.runRemaining()

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testCollect() {
    let stream = Stream.sequence([1, 2, 3])
    let collected = stream.collect()
    collected.expectNext([[1, 2, 3]])
  }

  func testConcatWith() {
    let bob = Scheduler()
    let eve = Scheduler()

    let streamA = Stream.sequence([1, 2]).observeIn(bob.context)
    let streamB = Stream.sequence([3, 4]).observeIn(eve.context)
    let merged = streamA.concatWith(streamB)
    
    let expectation = expectationWithDescription("completed")
    merged.expectNext([1, 2, 3, 4], expectation: expectation)

    bob.runOne()
    eve.runOne()
    bob.runRemaining()
    eve.runRemaining()

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testDefaultIfEmpty() {
    let stream = Stream.sequence([])
    let defaulted = stream.defaultIfEmpty(1)
    defaulted.expectNext([1])
  }

  func testReduce() {
    let stream = Stream.sequence([1, 2, 3])
    let reduced = stream.reduce(0, +)
    reduced.expectNext([6])
  }

  func testZipPrevious() {
    let stream = Stream.sequence([1, 2, 3])
    let zipped = stream.zipPrevious()
    zipped.expectNext([(nil, 1), (1, 2), (2, 3)])
  }

  func testFlatMapMerge() {
    let bob = Scheduler()
    let eves = [Scheduler(), Scheduler()]

    let stream = Stream.sequence([1, 2]).observeIn(bob.context)
    let merged = stream.flatMap(.Merge) { num in
      return Stream.sequence([5, 6].map { $0 * num }).observeIn(eves[num-1].context)
    }

    let expectation = expectationWithDescription("completed")
    merged.expectNext([5, 10, 12, 6], expectation: expectation)

    bob.runOne()
    eves[0].runOne()
    bob.runRemaining()
    eves[1].runRemaining()
    eves[0].runRemaining()

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testFlatMapLatest() {
    let bob = Scheduler()
    let eves = [Scheduler(), Scheduler()]

    let stream = Stream.sequence([1, 2]).observeIn(bob.context)
    let merged = stream.flatMap(.Latest) { num in
      return Stream.sequence([5, 6].map { $0 * num }).observeIn(eves[num-1].context)
    }

    let expectation = expectationWithDescription("completed")
    merged.expectNext([5, 10, 12], expectation: expectation)

    bob.runOne()
    eves[0].runOne()
    bob.runRemaining()
    eves[1].runRemaining()
    eves[0].runRemaining()

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testFlatMapConcat() {
    let bob = Scheduler()
    let eves = [Scheduler(), Scheduler()]

    let stream = Stream.sequence([1, 2]).observeIn(bob.context)
    let merged = stream.flatMap(.Concat) { num in
      return Stream.sequence([5, 6].map { $0 * num }).observeIn(eves[num-1].context)
    }

    let expectation = expectationWithDescription("completed")
    merged.expectNext([5, 6, 10, 12], expectation: expectation)

    bob.runRemaining()
    eves[1].runOne()
    eves[0].runRemaining()
    eves[1].runRemaining()

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testReplay() {
    let bob = Scheduler()
    bob.runRemaining()

    let stream = Stream.sequence([1, 2, 3]).executeIn(bob.context)
    let replayed = stream.replay(2)

    replayed.expectNext([1, 2, 3])
    replayed.connect()
    replayed.expectNext([2, 3])
    XCTAssertEqual(bob.numberOfRuns, 1)
  }

  func testPublish() {
    let bob = Scheduler()
    bob.runRemaining()

    let stream = Stream.sequence([1, 2, 3]).executeIn(bob.context)
    let published = stream.publish()

    published.expectNext([1, 2, 3])
    published.connect()
    published.expectNext([])

    XCTAssertEqual(bob.numberOfRuns, 1)
  }
}
