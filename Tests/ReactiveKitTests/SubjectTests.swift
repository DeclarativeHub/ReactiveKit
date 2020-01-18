//
//  SubjectTests.swift
//  ReactiveKit
//
//  Created by Théophane Rupin on 5/17/19.
//  Copyright © 2019 DeclarativeHub. All rights reserved.
//

import XCTest
import ReactiveKit

final class SubjectTests: XCTestCase {
    
    // MARK: - Subject
    
    func testSubjectForThreadSafety_oneEventDispatchedOnALotOfSubjects() {
        let exp = expectation(description: "race_condition?")
        exp.expectedFulfillmentCount = 10000
        
        for _ in 0..<exp.expectedFulfillmentCount {
            let disposeBag = DisposeBag()
            let subject = PassthroughSubject<Int, Never>()
            subject.stress(with: [subject], eventsCount: 1, expectation: exp).dispose(in: disposeBag)
            DispatchQueue.main.async {
                disposeBag.dispose()
            }
        }

        waitForExpectations(timeout: 3)
    }
    
    func testSubjectForThreadSafety_lotsOfEventsDispatchedOnOneSubject() {
        let exp = expectation(description: "race_condition?")

        let disposeBag = DisposeBag()
        let subject = PassthroughSubject<Int, Never>()
       
        subject.stress(with: [subject],
                       queuesCount: 10,
                       eventsCount: 3000,
                       expectation: exp)
            .dispose(in: disposeBag)
        
        waitForExpectations(timeout: 3)
    }
    
    func testSubjectForThreadSafety_someEventsDispatchedOnSomeSubjects() {
        let exp = expectation(description: "race_condition?")
        exp.expectedFulfillmentCount = 100
        
        for _ in 0..<exp.expectedFulfillmentCount {
            let disposeBag = DisposeBag()
            let subject = PassthroughSubject<Int, Never>()
            subject.stress(with: [subject], expectation: exp).dispose(in: disposeBag)
            DispatchQueue.main.async {
                disposeBag.dispose()
            }
        }
        
        waitForExpectations(timeout: 3)
    }
    
    // MARK: - ReplaySubject
    
    func testReplaySubjectForThreadSafety_oneEventDispatchedOnALotOfSubjects() {
        let exp = expectation(description: "race_condition?")
        exp.expectedFulfillmentCount = 10000
        
        for _ in 0..<exp.expectedFulfillmentCount {
            let disposeBag = DisposeBag()
            let subject = ReplaySubject<Int, Never>()
            subject.stress(with: [subject], eventsCount: 1, expectation: exp).dispose(in: disposeBag)
            DispatchQueue.main.async {
                disposeBag.dispose()
            }
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testReplaySubjectForThreadSafety_lotsOfEventsDispatchedOnOneSubject() {
        let exp = expectation(description: "race_condition?")
        
        let disposeBag = DisposeBag()
        let subject = ReplaySubject<Int, Never>()
        
        subject.stress(with: [subject],
                       queuesCount: 10,
                       eventsCount: 3000,
                       expectation: exp)
            .dispose(in: disposeBag)
        
        waitForExpectations(timeout: 3)
    }
    
    func testReplaySubjectForThreadSafety_someEventsDispatchedOnSomeSubjects() {
        let exp = expectation(description: "race_condition?")
        exp.expectedFulfillmentCount = 100
        
        for _ in 0..<exp.expectedFulfillmentCount {
            let disposeBag = DisposeBag()
            let subject = ReplaySubject<Int, Never>()
            subject.stress(with: [subject], expectation: exp).dispose(in: disposeBag)
            DispatchQueue.main.async {
                disposeBag.dispose()
            }
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testReplaySubjectForThreadSafetySendLast() {
        
        let eventsCount = 10000
        
        let eventsExpectation = expectation(description: "events")
        eventsExpectation.expectedFulfillmentCount = eventsCount
        
        let countDispatchQueue = DispatchQueue(label: "count")
        var actualEventsCount = 0
        
        for _ in 0..<eventsCount {
            let disposeBag = DisposeBag()
            let subject = ReplaySubject<Int, Never>()
            
            let dispatchQueueOne = DispatchQueue(label: "one")
            dispatchQueueOne.async {
                subject.observeNext { _ in
                    countDispatchQueue.async {
                        actualEventsCount += 1
                    }
                    eventsExpectation.fulfill()
                }.dispose(in: disposeBag)
            }
            
            let dispatchQueueTwo = DispatchQueue(label: "two")
            dispatchQueueTwo.async {
                subject.send(1)
                disposeBag.dispose()
            }
        }
        
        waitForExpectations(timeout: 2) { _ in
            countDispatchQueue.sync {
                guard actualEventsCount != eventsCount else { return }
                XCTFail("Short by \(eventsCount - actualEventsCount).")
            }
        }
    }
    
    func testReplaySubjectForThreadSafetySendFirst() {
        
        let eventsCount = 10000
        
        let eventsExpectation = expectation(description: "events")
        eventsExpectation.expectedFulfillmentCount = eventsCount
        
        let countDispatchQueue = DispatchQueue(label: "count")
        var actualEventsCount = 0
        
        for _ in 0..<eventsCount {
            let disposeBag = DisposeBag()
            let subject = ReplaySubject<Int, Never>()
            
            let dispatchQueueTwo = DispatchQueue(label: "two")
            dispatchQueueTwo.async {
                subject.send(1)
                disposeBag.dispose()
            }
            
            let dispatchQueueOne = DispatchQueue(label: "one")
            dispatchQueueOne.async {
                subject.observeNext { _ in
                    countDispatchQueue.async {
                        actualEventsCount += 1
                    }
                    eventsExpectation.fulfill()
                }.dispose(in: disposeBag)
            }
        }
        
        waitForExpectations(timeout: 2) { _ in
            countDispatchQueue.sync {
                guard actualEventsCount != eventsCount else { return }
                XCTFail("Short by \(eventsCount - actualEventsCount).")
            }
        }
    }
    
    // MARK: - ReplayOneSubject
    
    func testReplayOneSubjectForThreadSafety_oneEventDispatchedOnALotOfSubjects() {
        let exp = expectation(description: "race_condition?")
        exp.expectedFulfillmentCount = 10000
        
        for _ in 0..<exp.expectedFulfillmentCount {
            let disposeBag = DisposeBag()
            let subject = ReplayOneSubject<Int, Never>()
            subject.stress(with: [subject], eventsCount: 1, expectation: exp).dispose(in: disposeBag)
            DispatchQueue.main.async {
                disposeBag.dispose()
            }
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testReplayOneSubjectForThreadSafety_lotsOfEventsDispatchedOnOneSubject() {
        let exp = expectation(description: "race_condition?")
        
        let disposeBag = DisposeBag()
        let subject = ReplayOneSubject<Int, Never>()
        
        subject.stress(with: [subject],
                       queuesCount: 10,
                       eventsCount: 3000,
                       expectation: exp)
            .dispose(in: disposeBag)
        
        waitForExpectations(timeout: 3)
    }
    
    func testReplayOneSubjectForThreadSafety_someEventsDispatchedOnSomeSubjects() {
        let exp = expectation(description: "race_condition?")
        exp.expectedFulfillmentCount = 100
        
        for _ in 0..<exp.expectedFulfillmentCount {
            let disposeBag = DisposeBag()
            let subject = ReplayOneSubject<Int, Never>()
            subject.stress(with: [subject], expectation: exp).dispose(in: disposeBag)
            DispatchQueue.main.async {
                disposeBag.dispose()
            }
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testReplayOneSubjectForThreadSafetySendLast() {
        
        let eventsCount = 10000

        let eventsExpectation = expectation(description: "events")
        eventsExpectation.expectedFulfillmentCount = eventsCount

        let countDispatchQueue = DispatchQueue(label: "count")
        var actualEventsCount = 0
        
        for _ in 0..<eventsCount {
            let disposeBag = DisposeBag()
            let subject = ReplayOneSubject<Int, Never>()

            let dispatchQueueOne = DispatchQueue(label: "one")
            dispatchQueueOne.async {
                subject.observeNext { _ in
                    countDispatchQueue.async {
                        actualEventsCount += 1
                    }
                    eventsExpectation.fulfill()
                }.dispose(in: disposeBag)
            }
            
            let dispatchQueueTwo = DispatchQueue(label: "two")
            dispatchQueueTwo.async {
                subject.send(1)
                disposeBag.dispose()
            }
        }
        
        waitForExpectations(timeout: 2) { _ in
            countDispatchQueue.sync {
                guard actualEventsCount != eventsCount else { return }
                XCTFail("Short by \(eventsCount - actualEventsCount).")
            }
        }
    }

    func testReplayOneSubjectForThreadSafetySendFirst() {
        
        let eventsCount = 10000
        
        let eventsExpectation = expectation(description: "events")
        eventsExpectation.expectedFulfillmentCount = eventsCount
        
        let countDispatchQueue = DispatchQueue(label: "count")
        var actualEventsCount = 0
        
        for _ in 0..<eventsCount {
            let disposeBag = DisposeBag()
            let subject = ReplayOneSubject<Int, Never>()
            
            let dispatchQueueTwo = DispatchQueue(label: "two")
            dispatchQueueTwo.async {
                subject.send(1)
                disposeBag.dispose()
            }
            
            let dispatchQueueOne = DispatchQueue(label: "one")
            dispatchQueueOne.async {
                subject.observeNext { _ in
                    countDispatchQueue.async {
                        actualEventsCount += 1
                    }
                    eventsExpectation.fulfill()
                }.dispose(in: disposeBag)
            }
        }
        
        waitForExpectations(timeout: 2) { _ in
            countDispatchQueue.sync {
                guard actualEventsCount != eventsCount else { return }
                XCTFail("Short by \(eventsCount - actualEventsCount).")
            }
        }
    }
    
    // MARK: - ReplayLoadingValueSubject
    
    func testReplayLoadingValueSubjectForThreadSafety_oneEventDispatchedOnALotOfSubjects() {
        let exp = expectation(description: "race_condition?")
        exp.expectedFulfillmentCount = 10000
        
        for _ in 0..<exp.expectedFulfillmentCount {
            let disposeBag = DisposeBag()
            let subject = ReplayLoadingValueSubject<Int, Never, Never>()

            subject.stress(with: [{ subject.send(.loaded($0)) }],
                           eventsCount: 1,
                           expectation: exp)
                .dispose(in: disposeBag)

            DispatchQueue.main.async {
                disposeBag.dispose()
            }
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testReplayLoadingValueSubjectForThreadSafety_lotsOfEventsDispatchedOnOneSubject() {
        let exp = expectation(description: "race_condition?")
        
        let disposeBag = DisposeBag()
        let subject = ReplayLoadingValueSubject<Int, Never, Never>()
        
        subject.stress(with: [{ subject.send(.loaded($0)) }],
                       queuesCount: 10,
                       eventsCount: 3000,
                       expectation: exp)
            .dispose(in: disposeBag)
        
        waitForExpectations(timeout: 3)
    }
    
    func testReplayLoadingValueSubjectForThreadSafety_someEventsDispatchedOnSomeSubjects() {
        let exp = expectation(description: "race_condition?")
        exp.expectedFulfillmentCount = 100
        
        for _ in 0..<exp.expectedFulfillmentCount {
            let disposeBag = DisposeBag()
            let subject = ReplayLoadingValueSubject<Int, Never, Never>()

            subject.stress(with: [{ subject.send(.loaded($0)) }],
                           expectation: exp)
                .dispose(in: disposeBag)

            DispatchQueue.main.async {
                disposeBag.dispose()
            }
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testReplayLoadingValueSubjectForThreadSafetySendLast() {
        
        let eventsCount = 10000
        
        let eventsExpectation = expectation(description: "events")
        eventsExpectation.expectedFulfillmentCount = eventsCount
        
        let countDispatchQueue = DispatchQueue(label: "count")
        var actualEventsCount = 0
        
        for _ in 0..<eventsCount {
            let disposeBag = DisposeBag()
            let subject = ReplayLoadingValueSubject<Int, Never, Never>()
            
            let dispatchQueueOne = DispatchQueue(label: "one")
            dispatchQueueOne.async {
                subject.observeNext { _ in
                    countDispatchQueue.async {
                        actualEventsCount += 1
                    }
                    eventsExpectation.fulfill()
                }.dispose(in: disposeBag)
            }
            
            let dispatchQueueTwo = DispatchQueue(label: "two")
            dispatchQueueTwo.async {
                subject.send(.loaded(1))
                disposeBag.dispose()
            }
        }
        
        waitForExpectations(timeout: 2) { _ in
            countDispatchQueue.sync {
                guard actualEventsCount != eventsCount else { return }
                XCTFail("Short by \(eventsCount - actualEventsCount).")
            }
        }
    }
    
    func testReplayLoadingValueSubjectForThreadSafetySendFirst() {
        
        let eventsCount = 10000
        
        let eventsExpectation = expectation(description: "events")
        eventsExpectation.expectedFulfillmentCount = eventsCount
        
        let countDispatchQueue = DispatchQueue(label: "count")
        var actualEventsCount = 0
        
        for _ in 0..<eventsCount {
            let disposeBag = DisposeBag()
            let subject = ReplayLoadingValueSubject<Int, Never, Never>()
            
            let dispatchQueueTwo = DispatchQueue(label: "two")
            dispatchQueueTwo.async {
                subject.send(.loaded(1))
                disposeBag.dispose()
            }
            
            let dispatchQueueOne = DispatchQueue(label: "one")
            dispatchQueueOne.async {
                subject.observeNext { _ in
                    countDispatchQueue.async {
                        actualEventsCount += 1
                    }
                    eventsExpectation.fulfill()
                }.dispose(in: disposeBag)
            }
        }
        
        waitForExpectations(timeout: 2) { _ in
            countDispatchQueue.sync {
                guard actualEventsCount != eventsCount else { return }
                XCTFail("Short by \(eventsCount - actualEventsCount).")
            }
        }
    }
}


extension SubjectTests {

    static var allTests : [(String, (SubjectTests) -> () -> Void)] {
        return [
            ("testSubjectForThreadSafety_oneEventDispatchedOnALotOfSubjects", testSubjectForThreadSafety_oneEventDispatchedOnALotOfSubjects),
            ("testSubjectForThreadSafety_lotsOfEventsDispatchedOnOneSubject", testSubjectForThreadSafety_lotsOfEventsDispatchedOnOneSubject),
            ("testSubjectForThreadSafety_someEventsDispatchedOnSomeSubjects", testSubjectForThreadSafety_someEventsDispatchedOnSomeSubjects),

            ("testReplaySubjectForThreadSafety_oneEventDispatchedOnALotOfSubjects", testReplaySubjectForThreadSafety_oneEventDispatchedOnALotOfSubjects),
            ("testReplaySubjectForThreadSafety_lotsOfEventsDispatchedOnOneSubject", testReplaySubjectForThreadSafety_lotsOfEventsDispatchedOnOneSubject),
            ("testReplaySubjectForThreadSafety_someEventsDispatchedOnSomeSubjects", testReplaySubjectForThreadSafety_someEventsDispatchedOnSomeSubjects),

            ("testReplayOneSubjectForThreadSafety_oneEventDispatchedOnALotOfSubjects", testReplayOneSubjectForThreadSafety_oneEventDispatchedOnALotOfSubjects),
            ("testReplayOneSubjectForThreadSafety_lotsOfEventsDispatchedOnOneSubject", testReplayOneSubjectForThreadSafety_lotsOfEventsDispatchedOnOneSubject),
            ("testReplayOneSubjectForThreadSafety_someEventsDispatchedOnSomeSubjects", testReplayOneSubjectForThreadSafety_someEventsDispatchedOnSomeSubjects),

            ("testReplayLoadingValueSubjectForThreadSafety_oneEventDispatchedOnALotOfSubjects", testReplayLoadingValueSubjectForThreadSafety_oneEventDispatchedOnALotOfSubjects),
            ("testReplayLoadingValueSubjectForThreadSafety_lotsOfEventsDispatchedOnOneSubject", testReplayLoadingValueSubjectForThreadSafety_lotsOfEventsDispatchedOnOneSubject),
            ("testReplayLoadingValueSubjectForThreadSafety_someEventsDispatchedOnSomeSubjects", testReplayLoadingValueSubjectForThreadSafety_someEventsDispatchedOnSomeSubjects),
        ]
    }
}
