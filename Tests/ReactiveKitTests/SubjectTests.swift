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
    
    func testSubjectForThreadSafety() {
        
        let eventsCount = 10000
        
        for _ in 0..<eventsCount {
            let bag = DisposeBag()
            let subject = Subject<Int, Never>()
            
            let dispatchQueueOne = DispatchQueue(label: "one")
            dispatchQueueOne.async {
                subject.observe { _ in }.dispose(in: bag)
            }
            
            let dispatchQueueTwo = DispatchQueue(label: "two")
            dispatchQueueTwo.async {
                subject.next(1)
                bag.dispose()
            }
        }

        let waitForRaceConditionExpectation = expectation(description: "race_condition?")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            waitForRaceConditionExpectation.fulfill()
        }
        wait(for: [waitForRaceConditionExpectation], timeout: 3)
    }
    
    // MARK: - ReplaySubject
    
    func testReplaySubjectForThreadSafetySendLast() {
        
        let eventsCount = 10000
        
        let eventsExpectation = expectation(description: "events")
        eventsExpectation.expectedFulfillmentCount = eventsCount
        
        let countDispatchQueue = DispatchQueue(label: "count")
        var actualEventsCount = 0
        
        for _ in 0..<eventsCount {
            let bag = DisposeBag()
            let subject = ReplaySubject<Int, Never>()
            
            let dispatchQueueOne = DispatchQueue(label: "one")
            dispatchQueueOne.async {
                subject.observeNext { _ in
                    countDispatchQueue.async {
                        actualEventsCount += 1
                    }
                    eventsExpectation.fulfill()
                }.dispose(in: bag)
            }
            
            let dispatchQueueTwo = DispatchQueue(label: "two")
            dispatchQueueTwo.async {
                subject.next(1)
                bag.dispose()
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
            let bag = DisposeBag()
            let subject = ReplaySubject<Int, Never>()
            
            let dispatchQueueTwo = DispatchQueue(label: "two")
            dispatchQueueTwo.async {
                subject.next(1)
                bag.dispose()
            }
            
            let dispatchQueueOne = DispatchQueue(label: "one")
            dispatchQueueOne.async {
                subject.observeNext { _ in
                    countDispatchQueue.async {
                        actualEventsCount += 1
                    }
                    eventsExpectation.fulfill()
                    }.dispose(in: bag)
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
    
    func testReplayOneSubjectForThreadSafetySendLast() {
        
        let eventsCount = 10000

        let eventsExpectation = expectation(description: "events")
        eventsExpectation.expectedFulfillmentCount = eventsCount

        let countDispatchQueue = DispatchQueue(label: "count")
        var actualEventsCount = 0
        
        for _ in 0..<eventsCount {
            let bag = DisposeBag()
            let subject = ReplayOneSubject<Int, Never>()

            let dispatchQueueOne = DispatchQueue(label: "one")
            dispatchQueueOne.async {
                subject.observeNext { _ in
                    countDispatchQueue.async {
                        actualEventsCount += 1
                    }
                    eventsExpectation.fulfill()
                }.dispose(in: bag)
            }
            
            let dispatchQueueTwo = DispatchQueue(label: "two")
            dispatchQueueTwo.async {
                subject.next(1)
                bag.dispose()
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
            let bag = DisposeBag()
            let subject = ReplayOneSubject<Int, Never>()
            
            let dispatchQueueTwo = DispatchQueue(label: "two")
            dispatchQueueTwo.async {
                subject.next(1)
                bag.dispose()
            }
            
            let dispatchQueueOne = DispatchQueue(label: "one")
            dispatchQueueOne.async {
                subject.observeNext { _ in
                    countDispatchQueue.async {
                        actualEventsCount += 1
                    }
                    eventsExpectation.fulfill()
                }.dispose(in: bag)
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
    
    func testReplayLoadingValueSubjectForThreadSafetySendLast() {
        
        let eventsCount = 10000
        
        let eventsExpectation = expectation(description: "events")
        eventsExpectation.expectedFulfillmentCount = eventsCount
        
        let countDispatchQueue = DispatchQueue(label: "count")
        var actualEventsCount = 0
        
        for _ in 0..<eventsCount {
            let bag = DisposeBag()
            let subject = ReplayLoadingValueSubject<Int, Never, Never>()
            
            let dispatchQueueOne = DispatchQueue(label: "one")
            dispatchQueueOne.async {
                subject.observeNext { _ in
                    countDispatchQueue.async {
                        actualEventsCount += 1
                    }
                    eventsExpectation.fulfill()
                }.dispose(in: bag)
            }
            
            let dispatchQueueTwo = DispatchQueue(label: "two")
            dispatchQueueTwo.async {
                subject.next(.loaded(1))
                bag.dispose()
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
            let bag = DisposeBag()
            let subject = ReplayLoadingValueSubject<Int, Never, Never>()
            
            let dispatchQueueTwo = DispatchQueue(label: "two")
            dispatchQueueTwo.async {
                subject.next(.loaded(1))
                bag.dispose()
            }
            
            let dispatchQueueOne = DispatchQueue(label: "one")
            dispatchQueueOne.async {
                subject.observeNext { _ in
                    countDispatchQueue.async {
                        actualEventsCount += 1
                    }
                    eventsExpectation.fulfill()
                }.dispose(in: bag)
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
