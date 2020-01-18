//
//  CombineTests.swift
//  ReactiveKit-Tests
//
//  Created by Srdan Rasic on 18/01/2020.
//  Copyright © 2020 DeclarativeHub. All rights reserved.
//

#if canImport(Combine)

import XCTest
import ReactiveKit
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class CombineTests: XCTestCase {

    func testPublisherToSignal() {
        let publisher = Combine.PassthroughSubject<Int, TestError>()
        let subscriber = ReactiveKit.Subscribers.Accumulator<Int, TestError>()
        publisher.toSignal().subscribe(subscriber)
        publisher.send(0)
        publisher.send(1)
        publisher.send(2)
        publisher.send(completion: .failure(.error))
        publisher.send(3)
        XCTAssertEqual(subscriber.values, [0, 1, 2])
        XCTAssertFalse(subscriber.isFinished)
        XCTAssertTrue(subscriber.isFailure)
    }

    func testSignalToPublisher() {
        let publisher = ReactiveKit.PassthroughSubject<Int, TestError>()
        var receivedValues: [Int] = []
        var receivedCompletion: Combine.Subscribers.Completion<TestError>? = nil

        let cancellable = publisher.toPublisher().sink(
            receiveCompletion: { (completion) in
                receivedCompletion = completion
            }, receiveValue: { value in
                receivedValues.append(value)
            }
        )

        publisher.send(0)
        publisher.send(1)
        publisher.send(2)
        publisher.send(completion: .failure(.error))
        publisher.send(3)

        XCTAssertEqual(receivedValues, [0, 1, 2])
        XCTAssertEqual(receivedCompletion, .failure(.error))

        cancellable.cancel()
    }
}

#endif
