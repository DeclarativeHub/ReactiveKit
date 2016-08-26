//
//  OperatorTests.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 12/04/16.
//  Copyright © 2016 Srdan Rasic. All rights reserved.
//

import XCTest
@testable import ReactiveKit

enum TestError: Swift.Error {
  case Error
}

class SignalTests: XCTestCase {

  func testProductionAndObservation() {
    let bob = Scheduler()
    bob.runRemaining()

    let operation = Signal<Int, TestError>.sequence([1, 2, 3]).executeIn(bob.context)

    operation.expectNext([1, 2, 3])
    operation.expectNext([1, 2, 3])
    XCTAssertEqual(bob.numberOfRuns, 2)
  }

  func testDisposing() {
    let disposable = SimpleDisposable()

    let operation = Signal<Int, TestError> { _ in
      return disposable
    }

    operation.observe { _ in }.dispose()
    XCTAssertTrue(disposable.isDisposed)
  }

  func testJust() {
    let operation = Signal<Int, TestError>.just(1)
    operation.expectNext([1])
  }

  func testSequence() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    operation.expectNext([1, 2, 3])
  }

  func testCompleted() {
    let operation = Signal<Int, TestError>.completed()
    operation.expectNext([])
  }

  func testNever() {
    let operation = Signal<Int, TestError>.never()
    operation.expectNext([])
  }

  func testFailed() {
    let operation = Signal<Int, TestError>.failed(.Error)
    operation.expect([.failed(.Error)])
  }

  func testBuffer() {
    let operation = Signal<Int, TestError>.sequence([1,2,3,4,5])
    let buffered = operation.buffer(size: 2)
    buffered.expectNext([[1, 2], [3, 4]])
  }

  func testMap() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    let mapped = operation.map { $0 * 2 }
    mapped.expectNext([2, 4, 6])
  }

  func testScan() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    let scanned = operation.scan(0, +)
    scanned.expectNext([0, 1, 3, 6])
  }

  func testToSignal() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    let operation2 = operation.toSignal()
    operation2.expectNext([1, 2, 3])
  }

  func testSuppressError() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    let signal = operation.suppressError(logging: false)
    signal.expectNext([1, 2, 3])
  }

  func testSuppressError2() {
    let operation = Signal<Int, TestError>.failed(.Error)
    let signal = operation.suppressError(logging: false)
    signal.expectNext([])
  }

  func testRecover() {
    let operation = Signal<Int, TestError>.failed(.Error)
    let signal = operation.recover(with: 1)
    signal.expectNext([1])
  }

  func testWindow() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    let window = operation.window(size: 2)
    window.merge().expectNext([1, 2])
  }

  //  func testDebounce() {
  //    let operation = Signal<Int, TestError>.interval(0.1, queue: Queue.global).take(first: 3)
  //    let distinct = operation.debounce(interval: 0.3, on: Queue.global)
  //    let exp = expectation(withDescription: "completed")
  //    distinct.expectNext([2], expectation: exp)
  //    waitForExpectations(withTimeout: 1, handler: nil)
  //  }

  func testDistinct() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 2, 3])
    let distinct = operation.distinct { a, b in a != b }
    distinct.expectNext([1, 2, 3])
  }

  func testDistinct2() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 2, 3])
    let distinct = operation.distinct()
    distinct.expectNext([1, 2, 3])
  }

  func testElementAt() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    let elementAt1 = operation.element(at: 1)
    elementAt1.expectNext([2])
  }

  func testFilter() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    let filtered = operation.filter { $0 % 2 != 0 }
    filtered.expectNext([1, 3])
  }

  func testFirst() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    let first = operation.first()
    first.expectNext([1])
  }

  func testIgnoreElement() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    let ignoreElements = operation.ignoreElements()
    ignoreElements.expectNext([])
  }

  func testLast() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    let first = operation.last()
    first.expectNext([3])
  }

  // TODO: sample

  func testSkip() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    let skipped1 = operation.skip(first: 1)
    skipped1.expectNext([2, 3])
  }

  func testSkipLast() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    let skippedLast1 = operation.skip(last: 1)
    skippedLast1.expectNext([1, 2])
  }

  func testTake() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    let taken2 = operation.take(first: 2)
    taken2.expectNext([1, 2])
  }

  func testTakeLast() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    let takenLast2 = operation.take(last: 2)
    takenLast2.expectNext([2, 3])
  }

//  func testThrottle() {
//    let operation = Signal<Int, TestError>.interval(0.4, queue: Queue.global).take(5)
//    let distinct = operation.throttle(1)
//    let exp = expectation(withDescription: "completed")
//    distinct.expectNext([0, 3], expectation: exp)
//    waitForExpectationsWithTimeout(3, handler: nil)
//  }

  func testIgnoreNil() {
    let operation = Signal<Int?, TestError>.sequence(Array<Int?>([1, nil, 3]))
    let unwrapped = operation.ignoreNil()
    unwrapped.expectNext([1, 3])
  }

  func testCombineLatestWith() {
    let bob = Scheduler()
    let eve = Scheduler()

    let operationA = Signal<Int, TestError>.sequence([1, 2, 3]).observeIn(bob.context)
    let operationB = Signal<String, TestError>.sequence(["A", "B", "C"]).observeIn(eve.context)
    let combined = operationA.combineLatest(with: operationB).map { "\($0)\($1)" }

    let exp = expectation(description: "completed")
    combined.expectNext(["1A", "1B", "2B", "3B", "3C"], expectation: exp)

    bob.runOne()
    eve.runOne()
    eve.runOne()
    bob.runRemaining()
    eve.runRemaining()

    waitForExpectations(timeout: 1, handler: nil)
  }

  func testMergeWith() {
    let bob = Scheduler()
    let eve = Scheduler()
    let operationA = Signal<Int, TestError>.sequence([1, 2, 3]).observeIn(bob.context)
    let operationB = Signal<Int, TestError>.sequence([4, 5, 6]).observeIn(eve.context)
    let merged = operationA.merge(with: operationB)

    let exp = expectation(description: "completed")
    merged.expectNext([1, 4, 5, 2, 6, 3], expectation: exp)

    bob.runOne()
    eve.runOne()
    eve.runOne()
    bob.runOne()
    eve.runRemaining()
    bob.runRemaining()

    waitForExpectations(timeout: 1, handler: nil)
  }

  func testStartWith() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    let startWith4 = operation.start(with: 4)
    startWith4.expectNext([4, 1, 2, 3])
  }

  func testZipWith() {
    let operationA = Signal<Int, TestError>.sequence([1, 2, 3])
    let operationB = Signal<String, TestError>.sequence(["A", "B"])
    let combined = operationA.zip(with: operationB).map { "\($0)\($1)" }
    combined.expectNext(["1A", "2B"])
  }

  func testFlatMapError() {
    let operation = Signal<Int, TestError>.failed(.Error)
    let recovered = operation.flatMapError { error in Signal<Int, TestError>.just(1) }
    recovered.expectNext([1])
  }

  func testFlatMapError2() {
    let operation = Signal<Int, TestError>.failed(.Error)
    let recovered = operation.flatMapError { error in Signal<Int, NoError>.just(1) }
    recovered.expectNext([1])
  }

  func testRetry() {
    let bob = Scheduler()
    bob.runRemaining()

    let operation = Signal<Int, TestError>.failed(.Error).executeIn(bob.context)
    let retry = operation.retry(times: 3)
    retry.expect([.failed(.Error)])

    XCTAssertEqual(bob.numberOfRuns, 4)
  }

  func testexecuteIn() {
    let bob = Scheduler()
    bob.runRemaining()

    let operation = Signal<Int, TestError>.sequence([1, 2, 3]).executeIn(bob.context)
    operation.expectNext([1, 2, 3])

    XCTAssertEqual(bob.numberOfRuns, 1)
  }

  // TODO: delay

  func testDoOn() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    var start = 0
    var next = 0
    var completed = 0
    var disposed = 0

    let d = operation.doOn(next: { _ in next += 1 }, start: { start += 1}, completed: { completed += 1}, disposed: { disposed += 1}).observe { _ in }

    XCTAssert(start == 1)
    XCTAssert(next == 3)
    XCTAssert(completed == 1)
    XCTAssert(disposed == 1)

    d.dispose()
    XCTAssert(disposed == 1)
  }

  func testobserveIn() {
    let bob = Scheduler()
    bob.runRemaining()

    let operation = Signal<Int, TestError>.sequence([1, 2, 3]).observeIn(bob.context)
    operation.expectNext([1, 2, 3])

    XCTAssertEqual(bob.numberOfRuns, 4) // 3 elements + completion
  }

  func testPausable() {
    let operation = PublishSubject<Int, TestError>()
    let controller = PublishSubject<Bool, TestError>()
    let paused = operation.shareReplay().pausable(by: controller)

    let exp = expectation(description: "completed")
    paused.expectNext([1, 3], expectation: exp)

    operation.next(1)
    controller.next(false)
    operation.next(2)
    controller.next(true)
    operation.next(3)
    operation.completed()

    waitForExpectations(timeout: 1, handler: nil)
  }

  func testTimeoutNoFailure() {
    let exp = expectation(description: "completed")
    Signal<Int, TestError>.just(1).timeout(after: 0.2, with: .Error, on: DispatchQueue.main).expectNext([1], expectation: exp)
    waitForExpectations(timeout: 1, handler: nil)
  }

  func testTimeoutFailure() {
    let exp = expectation(description: "completed")
    Signal<Int, TestError>.never().timeout(after: 0.5, with: .Error, on: DispatchQueue.main).expect([.failed(.Error)], expectation: exp)
    waitForExpectations(timeout: 1, handler: nil)
  }

  func testAmbWith() {
    let bob = Scheduler()
    let eve = Scheduler()

    let operationA = Signal<Int, TestError>.sequence([1, 2]).observeIn(bob.context)
    let operationB = Signal<Int, TestError>.sequence([3, 4]).observeIn(eve.context)
    let ambdWith = operationA.amb(with: operationB)

    let exp = expectation(description: "completed")
    ambdWith.expectNext([3, 4], expectation: exp)

    eve.runOne()
    bob.runRemaining()
    eve.runRemaining()

    waitForExpectations(timeout: 1, handler: nil)
  }

  func testCollect() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    let collected = operation.collect()
    collected.expectNext([[1, 2, 3]])
  }

  func testConcatWith() {
    let bob = Scheduler()
    let eve = Scheduler()

    let operationA = Signal<Int, TestError>.sequence([1, 2]).observeIn(bob.context)
    let operationB = Signal<Int, TestError>.sequence([3, 4]).observeIn(eve.context)
    let merged = operationA.concat(with: operationB)
    
    let exp = expectation(description: "completed")
    merged.expectNext([1, 2, 3, 4], expectation: exp)

    bob.runOne()
    eve.runOne()
    bob.runRemaining()
    eve.runRemaining()

    waitForExpectations(timeout: 1, handler: nil)
  }

  func testDefaultIfEmpty() {
    let operation = Signal<Int, TestError>.sequence([])
    let defaulted = operation.defaultIfEmpty(1)
    defaulted.expectNext([1])
  }

  func testReduce() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    let reduced = operation.reduce(0, +)
    reduced.expectNext([6])
  }

  func testZipPrevious() {
    let operation = Signal<Int, TestError>.sequence([1, 2, 3])
    let zipped = operation.zipPrevious()
    zipped.expectNext([(nil, 1), (1, 2), (2, 3)])
  }

  func testFlatMapMerge() {
    let bob = Scheduler()
    let eves = [Scheduler(), Scheduler()]

    let operation = Signal<Int, TestError>.sequence([1, 2]).observeIn(bob.context)
    let merged = operation.flatMapMerge { num in
      return Signal<Int, TestError>.sequence([5, 6].map { $0 * num }).observeIn(eves[num-1].context)
    }

    let exp = expectation(description: "completed")
    merged.expectNext([5, 10, 12, 6], expectation: exp)

    bob.runOne()
    eves[0].runOne()
    bob.runRemaining()
    eves[1].runRemaining()
    eves[0].runRemaining()

    waitForExpectations(timeout: 1, handler: nil)
  }

  func testFlatMapLatest() {
    let bob = Scheduler()
    let eves = [Scheduler(), Scheduler()]

    let operation = Signal<Int, TestError>.sequence([1, 2]).observeIn(bob.context)
    let merged = operation.flatMapLatest { num in
      return Signal<Int, TestError>.sequence([5, 6].map { $0 * num }).observeIn(eves[num-1].context)
    }

    let exp = expectation(description: "completed")
    merged.expectNext([5, 10, 12], expectation: exp)

    bob.runOne()
    eves[0].runOne()
    bob.runRemaining()
    eves[1].runRemaining()
    eves[0].runRemaining()

    waitForExpectations(timeout: 1, handler: nil)
  }

  func testFlatMapConcat() {
    let bob = Scheduler()
    let eves = [Scheduler(), Scheduler()]

    let operation = Signal<Int, TestError>.sequence([1, 2]).observeIn(bob.context)
    let merged = operation.flatMapConcat { num in
      return Signal<Int, TestError>.sequence([5, 6].map { $0 * num }).observeIn(eves[num-1].context)
    }

    let exp = expectation(description: "completed")
    merged.expectNext([5, 6, 10, 12], expectation: exp)

    bob.runRemaining()
    eves[1].runOne()
    eves[0].runRemaining()
    eves[1].runRemaining()

    waitForExpectations(timeout: 1, handler: nil)
  }

  func testReplay() {
    let bob = Scheduler()
    bob.runRemaining()

    let operation = Signal<Int, TestError>.sequence([1, 2, 3]).executeIn(bob.context)
    let replayed = operation.replay(2)

    replayed.expectNext([1, 2, 3])
    let _ = replayed.connect()
    replayed.expectNext([2, 3])
    XCTAssertEqual(bob.numberOfRuns, 1)
  }

  func testPublish() {
    let bob = Scheduler()
    bob.runRemaining()

    let operation = Signal<Int, TestError>.sequence([1, 2, 3]).executeIn(bob.context)
    let published = operation.publish()

    published.expectNext([1, 2, 3])
    let _ = published.connect()
    published.expectNext([])

    XCTAssertEqual(bob.numberOfRuns, 1)
  }
}
