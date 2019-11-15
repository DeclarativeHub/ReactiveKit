//
//  UserTests.swift
//  ReactiveKit-Tests
//
//  Created by Srdan Rasic on 15/11/2019.
//  Copyright © 2019 DeclarativeHub. All rights reserved.
//

import XCTest
import ReactiveKit

class UserTests: XCTestCase {

    func testDeadlock() {

        let disposeBag = DisposeBag()

        let queue = DispatchQueue(label: "TestSignal.Queue",
                                  qos: .userInitiated,
                                  attributes: DispatchQueue.Attributes.concurrent)

        let e = expectation(description: "Deadlock?")
        e.expectedFulfillmentCount = 500

        for _ in 0..<e.expectedFulfillmentCount {
            var signalCallCount = 0

            let signal = Signal<Bool, Error> { observer in
                signalCallCount += 1

                queue.async { [signalCallCount] in
                    switch signalCallCount {
                    case 4:
                        observer.receive(true)
                    default:
                        observer.receive(completion: .failure(TestError.Error))
                    }
                }

                return SimpleDisposable()
            }

            Signal<Bool, Error> { observer in
                let trigger = Signal<Int, Never>(
                    sequence: 0...,
                    interval: 0.01
                )
                return signal.retry(when: trigger).observe(with: observer.on)
            }
            .observeNext {
                if $0 {
                    e.fulfill()
                }
            }
            .dispose(in: disposeBag)
        }

        wait(for: [e], timeout: 5)
    }
}
