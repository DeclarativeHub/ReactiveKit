//
//  OperatorTests.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 12/04/16.
//  Copyright © 2016 Srdan Rasic. All rights reserved.
//

import XCTest
import ReactiveKit
import Dispatch

enum TestError: Swift.Error {
    case error
}

class SignalTests: XCTestCase {

    func testProductionAndObservation() {
        let bob = Scheduler()
        bob.runRemaining()

        let a = Subscribers.Accumulator<Int, TestError>()
        let b = Subscribers.Accumulator<Int, TestError>()

        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).subscribe(on: bob)

        publisher.subscribe(a)
        publisher.subscribe(b)
        
        XCTAssertEqual(a.values, [1, 2, 3])
        XCTAssertTrue(a.isFinished)

        XCTAssertEqual(b.values, [1, 2, 3])
        XCTAssertTrue(b.isFinished)

        XCTAssertEqual(bob.numberOfRuns, 2)
    }

    func testDisposing() {
        let e = expectation(description: "Disposed")
        let disposable = BlockDisposable {
            e.fulfill()
        }

        let operation = Signal<Int, TestError> { _ in
            return disposable
        }

        operation.observe { _ in }.dispose()
        wait(for: [e], timeout: 1)
    }

    func testJust() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(just: 1)
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [1])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testSequence() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3])
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [1, 2, 3])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testCompleted() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>.completed()
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testNever() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>.never()
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [])
        XCTAssertFalse(subscriber.isFinished)
    }

    func testFailed() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>.failed(.error)
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.error, TestError.error)
    }

    func testObserveFailed() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>.failed(.error)
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.error, TestError.error)
    }

    func testObserveCompleted() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>.completed()
        publisher.subscribe(subscriber)
        XCTAssertTrue(subscriber.isFinished)
    }

    func testBuffer() {
        let s1 = Subscribers.Accumulator<[Int], Never>()
        let p1 = SafeSignal(sequence: [1, 2, 3]).buffer(size: 1)
        p1.subscribe(s1)
        XCTAssertEqual(s1.values, [[1], [2], [3]])
        XCTAssertTrue(s1.isFinished)
        
        let s2 = Subscribers.Accumulator<[Int], Never>()
        let p2 = SafeSignal(sequence: [1, 2, 3, 4]).buffer(size: 2)
        p2.subscribe(s2)
        XCTAssertEqual(s2.values, [[1, 2], [3, 4]])
        XCTAssertTrue(s2.isFinished)

        let s3 = Subscribers.Accumulator<[Int], Never>()
        let p3 = SafeSignal(sequence: [1, 2, 3, 4, 5]).buffer(size: 2)
        p3.subscribe(s3)
        XCTAssertEqual(s3.values, [[1, 2], [3, 4]])
        XCTAssertTrue(s3.isFinished)
    }
    
    func testMap() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).map { $0 * 2 }
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [2, 4, 6])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testScan() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).scan(0, +)
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [0, 1, 3, 6])
        XCTAssertTrue(subscriber.isFinished)
    }
    
    func testScanForThreadSafety() {
        let subject = PassthroughSubject<Int, TestError>()
        let scanned = subject.scan(0, +)
        let disposeBag = DisposeBag()
        let exp = expectation(description: "race_condition?")
        scanned.stress(with: [subject], expectation: exp).dispose(in: disposeBag)
        waitForExpectations(timeout: 3)
    }

    func testToSignal() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).toSignal()
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [1, 2, 3])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testSuppressError() {
        let subscriber = Subscribers.Accumulator<Int, Never>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).suppressError(logging: false)
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [1, 2, 3])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testSuppressError2() {
        let subscriber = Subscribers.Accumulator<Int, Never>()
        let publisher = Signal<Int, TestError>.failed(.error).suppressError(logging: false)
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testRecover() {
        let subscriber = Subscribers.Accumulator<Int, Never>()
        let publisher = Signal<Int, TestError>.failed(.error).replaceError(with: 1)
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [1])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testWindow() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).window(ofSize: 2).merge()
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [1, 2])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testDistinct() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 2, 3]).removeDuplicates(by: ==)
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [1, 2, 3])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testDistinct2() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 2, 3]).removeDuplicates()
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [1, 2, 3])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testElementAt() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).output(at: 1)
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [2])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testFilter() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).filter { $0 % 2 != 0 }
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [1, 3])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testFirst() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).first()
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [1])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testIgnoreElement() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).ignoreOutput()
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testLast() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).last()
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [3])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testSkip() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).dropFirst(1)
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [2, 3])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testSkipLast() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).dropLast(1)
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [1, 2])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testTakeFirst() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).prefix(maxLength: 2)
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [1, 2])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testTakeLast() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).suffix(maxLength: 2)
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [2, 3])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testTakeFirstOne() {
        let subscriber = Subscribers.Accumulator<[Bool], Never>()
        Property(false)
            .prefix(maxLength: 1)
            .collect()
            .subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [[false]])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testTakeUntil() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()

        let bob = Scheduler()
        let eve = Scheduler()

        Signal<Int, TestError>(sequence: [1, 2, 3, 4])
            .receive(on: bob)
            .prefix(untilOutputFrom: Signal<String, TestError>(sequence: ["A", "B"]).receive(on: eve))
            .subscribe(subscriber)
        
        bob.runOne()                // Sends 1.
        bob.runOne()                // Sends 2.
        eve.runOne()                // Sends A, effectively stopping the receiver.
        bob.runOne()                // Ignored.
        eve.runRemaining()          // Ignored. Sends B, with termination.
        bob.runRemaining()          // Ignored.

        XCTAssertEqual(subscriber.values, [1, 2])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testDebounce() {
        // event 0            @ 0.0s - debounced
        // event 1            @ 0.4s - debounced
        // event 2            @ 0.8s - debounced
        // event 3            @ 1.2s - debounced
        // event 4            @ 1.6s - debounced
        // timesup            @ 2.6s - return 4
        // event 5            @ 3.6s - debounced
        // timesup            @ 4.6s - return 5
        let values = Signal<Int, Never>(sequence: 0..<5, interval: 0.4)
            .append(Signal<Int, Never>(just: 5, after: 2))
            .debounce(for: 1)
            .waitAndCollectElements()
        XCTAssertEqual(values, [4, 5])
    }
    
    func testThrottle() {
        // event 0            @ 0.0s - return 0
        // event 1            @ 0.4s - throttled
        // event 2            @ 0.8s - throttled
        // event 3            @ 1.2s - throttled
        // throttle timesup   @ 1.5s - return 3
        // event 4            @ 1.6s - throttled
        // event 5            @ 2.0s - throttled
        // event 6            @ 2.4s - throttled
        // event 7            @ 2.8s - throttled
        // throttle timesup   @ 3.0s - return 7
        // event 8            @ 3.2s - throttled
        // event 9            @ 3.6s - throttled
        // completed          @ 3.6s - return 9
        let values = Signal<Int, TestError>(sequence: 0..<10, interval: 0.4)
            .throttle(for: 1.5)
            .waitAndCollectElements()
        XCTAssertEqual(values, [0, 3, 7, 9])
    }

    func testIgnoreNils() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int?, TestError>(sequence: Array<Int?>([1, nil, 3])).ignoreNils()
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [1, 3])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testReplaceNils() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int?, TestError>(sequence: Array<Int?>([1, nil, 3, nil])).replaceNils(with: 7)
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [1, 7, 3, 7])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testCombineLatestWith() {
        let bob = Scheduler()
        let eve = Scheduler()

        let subscriber = Subscribers.Accumulator<String, TestError>()
        let a = Signal<Int, TestError>(sequence: [1, 2, 3]).receive(on: bob)
        let b = Signal<String, TestError>(sequence: ["A", "B", "C"]).receive(on: eve)
        let combined = a.combineLatest(with: b).map { "\($0)\($1)" }

        combined.subscribe(subscriber)

        bob.runOne()
        eve.runOne()
        eve.runOne()
        bob.runRemaining()
        eve.runRemaining()

        XCTAssertEqual(subscriber.values, ["1A", "1B", "2B", "3B", "3C"])
        XCTAssertTrue(subscriber.isFinished)
    }
    
    func testCombineLatestWithForThreadSafety() {
        let subjectOne = PassthroughSubject<Int, TestError>()
        let subjectTwo = PassthroughSubject<Int, TestError>()
        let combined = subjectOne.combineLatest(with: subjectTwo)
        
        let disposeBag = DisposeBag()
        let exp = expectation(description: "race_condition?")
        combined.stress(with: [subjectOne, subjectTwo], expectation: exp).dispose(in: disposeBag)
        
        waitForExpectations(timeout: 3)
    }

    func testMergeWith() {
        let bob = Scheduler()
        let eve = Scheduler()
        
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let a = Signal<Int, TestError>(sequence: [1, 2, 3]).receive(on: bob)
        let b = Signal<Int, TestError>(sequence: [4, 5, 6]).receive(on: eve)
        let merged = a.merge(with: b)

        merged.subscribe(subscriber)

        bob.runOne()
        eve.runOne()
        eve.runOne()
        bob.runOne()
        eve.runRemaining()
        bob.runRemaining()

        XCTAssertEqual(subscriber.values, [1, 4, 5, 2, 6, 3])
        XCTAssertTrue(subscriber.isFinished)
    }
    
    func testStartWith() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).prepend(4)
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [4, 1, 2, 3])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testZipWith() {
        let subscriber = Subscribers.Accumulator<String, TestError>()
        let a = Signal<Int, TestError>(sequence: [1, 2, 3])
        let b = Signal<String, TestError>(sequence: ["A", "B"])
        let combined = a.zip(with: b).map { "\($0)\($1)" }
        combined.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, ["1A", "2B"])
        XCTAssertTrue(subscriber.isFinished)
    }
    
    func testZipWithForThreadSafety() {
        let subjectOne = PassthroughSubject<Int, TestError>()
        let subjectTwo = PassthroughSubject<Int, TestError>()
        let combined = subjectOne.zip(with: subjectTwo)
        
        let disposeBag = DisposeBag()
        let exp = expectation(description: "race_condition?")
        combined.stress(with: [subjectOne, subjectTwo], expectation: exp).dispose(in: disposeBag)
        
        waitForExpectations(timeout: 3)
    }

    func testZipWithWhenNotComplete() {
        let subscriber = Subscribers.Accumulator<String, TestError>()
        let a = Signal<Int, TestError>(sequence: [1, 2, 3]).ignoreTerminal()
        let b = Signal<String, TestError>(sequence: ["A", "B"])
        let combined = a.zip(with: b).map { "\($0)\($1)" }
        combined.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, ["1A", "2B"])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testZipWithWhenNotComplete2() {
        let subscriber = Subscribers.Accumulator<String, TestError>()
        let a = Signal<Int, TestError>(sequence: [1, 2, 3])
        let b = Signal<String, TestError>(sequence: ["A", "B"]).ignoreTerminal()
        let combined = a.zip(with: b).map { "\($0)\($1)" }
        combined.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, ["1A", "2B"])
        XCTAssertFalse(subscriber.isFinished)
    }

    func testZipWithAsyncSignal() {
        let a = Signal<Int, TestError>(sequence: 0..<4, interval: 0.5)
        let b = Signal<Int, TestError>(sequence: 0..<10, interval: 1.0)
        let combined = a.zip(with: b).map { $0 + $1 } // Completes after 4 nexts due to 'a' and takes 4 secs due to 'b'
        let events = combined.waitAndCollectEvents()
        XCTAssertEqual(events, [.next(0), .next(2), .next(4), .next(6), .completed])
    }

    func testFlatMapError() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>.failed(.error).flatMapError { error in Signal<Int, TestError>(just: 1) }
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [1])
        XCTAssertFalse(subscriber.isFailure)
        XCTAssertTrue(subscriber.isFinished)
    }

    func testFlatMapError2() {
        let subscriber = Subscribers.Accumulator<Int, Never>()
        let publisher = Signal<Int, TestError>.failed(.error).flatMapError { error in Signal<Int, Never>(just: 1) }
        publisher.subscribe(subscriber)
        XCTAssertEqual(subscriber.values, [1])
        XCTAssertFalse(subscriber.isFailure)
        XCTAssertTrue(subscriber.isFinished)
    }

    func testRetry() {
        let bob = Scheduler()
        bob.runRemaining()

        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>.failed(.error).subscribe(on: bob).retry(3)
        publisher.subscribe(subscriber)

        XCTAssertEqual(subscriber.values, [])
        XCTAssertEqual(subscriber.error, .error)
        XCTAssertTrue(subscriber.isFailure)
        XCTAssertEqual(bob.numberOfRuns, 4)
    }
    
    func testRetryForThreadSafety() {
        let subjectOne = PassthroughSubject<Int, TestError>()
        let retry = subjectOne.retry(3)
        
        let disposeBag = DisposeBag()
        let exp = expectation(description: "race_condition?")
        retry.stress(with: [subjectOne], expectation: exp).dispose(in: disposeBag)
        
        waitForExpectations(timeout: 3)
    }

    func testRetryWhen() {

        let queue = DispatchQueue(label: "test", qos: .userInitiated)
        let e = expectation(description: "Failed to retry")
        e.expectedFulfillmentCount = 1000

        for _ in 0..<e.expectedFulfillmentCount {
            var count = 0
            _ = Signal { () -> Result<Bool, Error> in
                count += 1
                if count == 3 {
                    return .success(true)
                } else {
                    return .failure(TestError.error)
                }
            }
            .subscribe(on: queue)
            .retry(when: Signal(just: 1))
            .observeNext {
                if $0 {
                    e.fulfill()
                }
            }
        }

        wait(for: [e], timeout: 8)
    }

    func testExecuteIn() {
        let bob = Scheduler()
        bob.runRemaining()

        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).subscribe(on: bob)
        publisher.subscribe(subscriber)

        XCTAssertEqual(subscriber.values, [1, 2, 3])
        XCTAssertTrue(subscriber.isFinished)
        XCTAssertEqual(bob.numberOfRuns, 1)
    }

    func testDoOn() {
        let e = expectation(description: "Disposed")
        let operation = Signal<Int, Never>(sequence: [1, 2, 3])
        var start = 0
        var next = 0
        var completed = 0
        var disposed = 0 {
            didSet {
                e.fulfill()
            }
        }

        let d = operation.handleEvents(
            receiveSubscription: { start += 1 },
            receiveOutput: { _ in next += 1 },
            receiveCompletion: { _ in completed += 1 },
            receiveCancel: { disposed += 1 }
        ).sink { _ in }

        XCTAssert(start == 1)
        XCTAssert(next == 3)
        XCTAssert(completed == 1)

        d.dispose()
        wait(for: [e], timeout: 1)
    }

    func testObserveIn() {
        let bob = Scheduler()
        bob.runRemaining()

        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).receive(on: bob)
        publisher.subscribe(subscriber)

        XCTAssertEqual(subscriber.values, [1, 2, 3])
        XCTAssertTrue(subscriber.isFinished)
        XCTAssertEqual(bob.numberOfRuns, 4) // 3 elements + completion
    }

    func testPausable() {
        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let operation = PassthroughSubject<Int, TestError>()
        let controller = PassthroughSubject<Bool, TestError>()
        let paused = operation.share().pausable(by: controller)

        paused.subscribe(subscriber)

        operation.send(1)
        controller.send(false)
        operation.send(2)
        controller.send(true)
        operation.send(3)
        operation.send(completion: .finished)

        XCTAssertEqual(subscriber.values, [1, 3])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testTimeoutNoFailure() {
        let events = Signal<Int, TestError>(just: 1)
            .timeout(after: 0.2, with: .error)
            .waitAndCollectEvents()
        XCTAssertEqual(events, [.next(1), .completed])
    }

    func testTimeoutFailure() {
        let events = Signal<Int, TestError>
            .never()
            .timeout(after: 0.5, with: .error)
            .waitAndCollectEvents()
        XCTAssertEqual(events, [.failed(.error)])
    }
    
    func testTimeoutForThreadSafety() {
        let exp = expectation(description: "race_condition?")
        exp.expectedFulfillmentCount = 10000
        for _ in 0..<exp.expectedFulfillmentCount {
            let subject = PassthroughSubject<Int, TestError>()
            let timeout = subject.timeout(after: 1, with: .error)
            let disposeBag = DisposeBag()
            timeout.stress(with: [subject], eventsCount: 10, expectation: exp).dispose(in: disposeBag)
        }
        waitForExpectations(timeout: 3)
    }

    func testAmbWith() {
        let bob = Scheduler()
        let eve = Scheduler()

        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let a = Signal<Int, TestError>(sequence: [1, 2]).receive(on: bob)
        let b = Signal<Int, TestError>(sequence: [3, 4]).receive(on: eve)
        let ambWith = a.amb(with: b)
        ambWith.subscribe(subscriber)

        eve.runOne()
        bob.runRemaining()
        eve.runRemaining()

        XCTAssertEqual(subscriber.values, [3, 4])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testAmbForThreadSafety() {
        let subjectOne = PassthroughSubject<Int, TestError>()
        let subjectTwo = PassthroughSubject<Int, TestError>()
        let combined = subjectOne.amb(with: subjectTwo)
        
        let disposeBag = DisposeBag()
        let exp = expectation(description: "race_condition?")
        combined.stress(with: [subjectOne, subjectTwo], expectation: exp).dispose(in: disposeBag)
        
        waitForExpectations(timeout: 3)
    }
    
    func testCollect() {
        let events = Signal<Int, TestError>(sequence: [1, 2, 3])
            .collect()
            .waitAndCollectEvents()
        XCTAssertEqual(events, [.next([1, 2, 3]), .completed])
    }

    func testAppend() {
        let bob = Scheduler()
        let eve = Scheduler()

        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let a = Signal<Int, TestError>(sequence: [1, 2]).receive(on: bob)
        let b = Signal<Int, TestError>(sequence: [3, 4]).receive(on: eve)
        let merged = a.append(b)
        merged.subscribe(subscriber)

        bob.runOne()
        eve.runOne()
        bob.runRemaining()
        eve.runRemaining()

        XCTAssertEqual(subscriber.values, [1, 2, 3, 4])
        XCTAssertTrue(subscriber.isFinished)
    }
    
    func testWithLatestFrom() {
        let bob = Scheduler()
        let eve = Scheduler()

        let subscriber = Subscribers.Accumulator<(Int, Int), TestError>()
        let a = Signal<Int, TestError>(sequence: [1, 2, 5]).receive(on: bob)
        let b = Signal<Int, TestError>(sequence: [3, 4, 6]).receive(on: eve)
        let merged = a.with(latestFrom: b)
        merged.subscribe(subscriber)

        bob.runOne()
        eve.runOne()
        bob.runOne()
        eve.runOne()
        bob.runRemaining()
        eve.runRemaining()
        
        XCTAssertEqual(subscriber.values[0].0, 2)
        XCTAssertEqual(subscriber.values[0].1, 3)
        XCTAssertEqual(subscriber.values[1].0, 5)
        XCTAssertEqual(subscriber.values[1].1, 4)
        XCTAssertTrue(subscriber.isFinished)
    }
    
    func testWithLatestFromForThreadSafety() {
        let subjectOne = PassthroughSubject<Int, TestError>()
        let subjectTwo = PassthroughSubject<Int, TestError>()
        let merged = subjectOne.with(latestFrom: subjectTwo)
        
        let disposeBag = DisposeBag()
        let exp = expectation(description: "race_condition?")
        merged.stress(with: [subjectOne, subjectTwo], expectation: exp).dispose(in: disposeBag)
        
        waitForExpectations(timeout: 3)
    }

    func testReplaceEmpty() {
        let events = Signal<Int, TestError>(sequence: [])
            .replaceEmpty(with: 1)
            .waitAndCollectEvents()
        XCTAssertEqual(events, [.next(1), .completed])
    }

    func testReduce() {
        let events = Signal<Int, TestError>(sequence: [1, 2, 3])
            .reduce(0, +)
            .waitAndCollectEvents()
        XCTAssertEqual(events, [.next(6), .completed])
    }

    func testZipPrevious() {
        let events = Signal<Int, TestError>(sequence: [1, 2, 3])
            .zipPrevious()
            .waitAndCollectEvents()
        let expected: [Signal<(Int?, Int), TestError>.Event] = [.next((nil, 1)), .next((1, 2)), .next((2, 3)), .completed]
        XCTAssertEqual("\(events)", "\(expected)")
    }

    func testFlatMapMerge() {
        let bob = Scheduler()
        let eves = [Scheduler(), Scheduler()]

        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2])
            .receive(on: bob)
            .flatMapMerge { num in
                Signal<Int, TestError>(sequence: [5, 6].map { $0 * num }).receive(on: eves[num-1])
            }
        publisher.subscribe(subscriber)

        bob.runOne()
        eves[0].runOne()
        bob.runRemaining()
        eves[1].runRemaining()
        eves[0].runRemaining()

        XCTAssertEqual(subscriber.values, [5, 10, 12, 6])
        XCTAssertTrue(subscriber.isFinished)
    }
    
    func testFlatMapMergeForThreadSafety() {
        let subjectOne = PassthroughSubject<Int, TestError>()
        let subjectTwo = PassthroughSubject<Int, TestError>()
        let merged = subjectOne.flatMapMerge { _ in subjectTwo }
        
        let disposeBag = DisposeBag()
        let exp = expectation(description: "race_condition?")
        merged.stress(with: [subjectOne, subjectTwo], expectation: exp).dispose(in: disposeBag)
        
        waitForExpectations(timeout: 3)
    }

    func testFlatMapLatest() {
        let bob = Scheduler()
        let eves = [Scheduler(), Scheduler()]

        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2])
            .receive(on: bob)
            .flatMapLatest { num in
                Signal<Int, TestError>(sequence: [5, 6].map { $0 * num }).receive(on: eves[num-1])
            }
        publisher.subscribe(subscriber)

        bob.runOne()
        eves[0].runOne()
        bob.runRemaining()
        eves[1].runRemaining()
        eves[0].runRemaining()

        XCTAssertEqual(subscriber.values, [5, 10, 12])
        XCTAssertTrue(subscriber.isFinished)
    }
    
    func testFlatMapLatestForThreadSafety() {
        let subjectOne = PassthroughSubject<Int, TestError>()
        let subjectTwo = PassthroughSubject<Int, TestError>()
        let merged = subjectOne.flatMapLatest { _ in subjectTwo }
        
        let disposeBag = DisposeBag()
        let exp = expectation(description: "race_condition?")
        merged.stress(with: [subjectOne, subjectTwo], expectation: exp).dispose(in: disposeBag)
        
        waitForExpectations(timeout: 3)
    }

    func testFlatMapConcat() {
        let bob = Scheduler()
        let eves = [Scheduler(), Scheduler()]

        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let publisher = Signal<Int, TestError>(sequence: [1, 2])
            .receive(on: bob)
            .flatMapConcat { num in
                Signal<Int, TestError>(sequence: [5, 6].map { $0 * num }).receive(on: eves[num-1])
            }
        publisher.subscribe(subscriber)

        bob.runRemaining()
        eves[1].runOne()
        eves[0].runRemaining()
        eves[1].runRemaining()

        XCTAssertEqual(subscriber.values, [5, 6, 10, 12])
        XCTAssertTrue(subscriber.isFinished)
    }
    
    func testFlatMapConcatForThreadSafety() {
        let subjectOne = PassthroughSubject<Int, TestError>()
        let subjectTwo = PassthroughSubject<Int, TestError>()
        let merged = subjectOne.flatMapConcat { _ in subjectTwo }
        
        let disposeBag = DisposeBag()
        let exp = expectation(description: "race_condition?")
        merged.stress(with: [subjectOne, subjectTwo], expectation: exp).dispose(in: disposeBag)
        
        waitForExpectations(timeout: 3)
    }

    func testReplay() {
        let bob = Scheduler()
        bob.runRemaining()

        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).subscribe(on: bob)
        let replayed = publisher.replay(limit: 2)

        XCTAssertEqual(publisher.waitAndCollectEvents(), [.next(1), .next(2), .next(3), .completed])
        let _ = replayed.connect()
        XCTAssertEqual(replayed.waitAndCollectEvents(), [.next(2), .next(3), .completed])
        XCTAssertEqual(bob.numberOfRuns, 2)
    }

    func testReplayLatestWith() {
        let bob = Scheduler()
        let eve = Scheduler()

        let subscriber = Subscribers.Accumulator<Int, TestError>()
        let a = Signal<Int, TestError>(sequence: [1, 2, 3]).receive(on: bob)
        let b = Signal<String, Never>(sequence: ["A", "A", "A", "A", "A"]).receive(on: eve)
        let combined = a.replayLatest(when: b)
        combined.subscribe(subscriber)

        eve.runOne()
        eve.runOne()
        bob.runOne()
        bob.runOne()
        eve.runOne()
        eve.runOne()
        bob.runOne()
        eve.runRemaining()
        bob.runRemaining()

        XCTAssertEqual(subscriber.values, [1, 2, 2, 2, 3, 3])
        XCTAssertTrue(subscriber.isFinished)
    }
    
    func testReplayLatestWithForThreadSafety() {
        let subjectOne = PassthroughSubject<Int, Never>()
        let subjectTwo = PassthroughSubject<Int, Never>()
        let combined = subjectOne.replayLatest(when: subjectTwo)
        
        let disposeBag = DisposeBag()
        let exp = expectation(description: "race_condition?")
        combined.stress(with: [subjectOne, subjectTwo], expectation: exp).dispose(in: disposeBag)
        
        waitForExpectations(timeout: 3)
    }

    func testPublish() {
        let bob = Scheduler()
        bob.runRemaining()

        let publisher = Signal<Int, TestError>(sequence: [1, 2, 3]).subscribe(on: bob)
        let published = publisher.publish()

        XCTAssertEqual(publisher.waitAndCollectEvents(), [.next(1), .next(2), .next(3), .completed])
        let _ = published.connect()

        XCTAssertEqual(
            published.timeout(after: 1, with: .error).waitAndCollectEvents(),
            [.failed(.error)]
        )

        XCTAssertEqual(bob.numberOfRuns, 2)
    }

    func testAnyCancallableHashable() {
        let emptyClosure: () -> Void = { }

        let cancellable1 = AnyCancellable(emptyClosure)
        let cancellable2 = AnyCancellable(emptyClosure)
        let cancellable3 = AnyCancellable { print("Disposed") }
        let cancellable4 = cancellable3

        XCTAssertNotEqual(cancellable1, cancellable2)
        XCTAssertNotEqual(cancellable1, cancellable3)
        XCTAssertEqual(cancellable3, cancellable4)

    }

    #if  os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    func testBindTo() {

        class User: NSObject, BindingExecutionContextProvider {

            var age: Int = 0

            var bindingExecutionContext: ExecutionContext {
                return .immediate
            }
        }

        let user = User()

        SafeSignal(just: 20).bind(to: user) { (object, value) in object.age = value }
        XCTAssertEqual(user.age, 20)

        SafeSignal(just: 30).bind(to: user, keyPath: \.age)
        XCTAssertEqual(user.age, 30)
    }
    #endif
}

extension SignalTests {

    static var allTests : [(String, (SignalTests) -> () -> Void)] {
        return [
            ("testProductionAndObservation", testProductionAndObservation),
            ("testDisposing", testDisposing),
            ("testJust", testJust),
            ("testSequence", testSequence),
            ("testCompleted", testCompleted),
            ("testNever", testNever),
            ("testFailed", testFailed),
            ("testObserveFailed", testObserveFailed),
            ("testObserveCompleted", testObserveCompleted),
            ("testBuffer", testBuffer),
            ("testMap", testMap),
            ("testScan", testScan),
            ("testScanForThreadSafety", testScanForThreadSafety),
            ("testToSignal", testToSignal),
            ("testSuppressError", testSuppressError),
            ("testSuppressError2", testSuppressError2),
            ("testRecover", testRecover),
            ("testWindow", testWindow),
            ("testDistinct", testDistinct),
            ("testDistinct2", testDistinct2),
            ("testElementAt", testElementAt),
            ("testFilter", testFilter),
            ("testFirst", testFirst),
            ("testIgnoreElement", testIgnoreElement),
            ("testLast", testLast),
            ("testSkip", testSkip),
            ("testSkipLast", testSkipLast),
            ("testTakeFirst", testTakeFirst),
            ("testTakeLast", testTakeLast),
            ("testTakeFirstOne", testTakeFirstOne),
            ("testTakeUntil", testTakeUntil),
            ("testIgnoreNils", testIgnoreNils),
            ("testReplaceNils", testReplaceNils),
            ("testCombineLatestWith", testCombineLatestWith),
            ("testCombineLatestWithForThreadSafety", testCombineLatestWithForThreadSafety),
            ("testMergeWith", testMergeWith),
            ("testStartWith", testStartWith),
            ("testZipWith", testZipWith),
            ("testZipWithForThreadSafety", testZipWithForThreadSafety),
            ("testZipWithWhenNotComplete", testZipWithWhenNotComplete),
            ("testZipWithWhenNotComplete2", testZipWithWhenNotComplete2),
            ("testZipWithAsyncSignal", testZipWithAsyncSignal),
            ("testFlatMapError", testFlatMapError),
            ("testFlatMapError2", testFlatMapError2),
            ("testRetry", testRetry),
            ("testRetryForThreadSafety", testRetryForThreadSafety),
            ("testRetryWhen", testRetryWhen),
            ("testExecuteIn", testExecuteIn),
            ("testDoOn", testDoOn),
            ("testObserveIn", testObserveIn),
            ("testPausable", testPausable),
            ("testTimeoutNoFailure", testTimeoutNoFailure),
            ("testTimeoutFailure", testTimeoutFailure),
            ("testTimeoutForThreadSafety", testTimeoutForThreadSafety),
            ("testAmbWith", testAmbWith),
            ("testAmbForThreadSafety", testAmbForThreadSafety),
            ("testCollect", testCollect),
            ("testAppend", testAppend),
            ("testWithLatestFrom", testWithLatestFrom),
            ("testWithLatestFromForThreadSafety", testWithLatestFromForThreadSafety),
            ("testReplaceEmpty", testReplaceEmpty),
            ("testReduce", testReduce),
            ("testZipPrevious", testZipPrevious),
            ("testFlatMapMerge", testFlatMapMerge),
            ("testFlatMapMergeForThreadSafety", testFlatMapMergeForThreadSafety),
            ("testFlatMapLatest", testFlatMapLatest),
            ("testFlatMapLatestForThreadSafety", testFlatMapLatestForThreadSafety),
            ("testFlatMapConcat", testFlatMapConcat),
            ("testFlatMapConcatForThreadSafety", testFlatMapConcatForThreadSafety),
            ("testReplay", testReplay),
            ("testReplayLatestWith", testReplayLatestWith),
            ("testReplayLatestWithForThreadSafety", testReplayLatestWithForThreadSafety),
            ("testPublish", testPublish),
            ("testAnyCancallableHashable", testAnyCancallableHashable)
        ]
    }
}
