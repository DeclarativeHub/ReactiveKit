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

    func testDeadlockOnRetryWhen() {

        let e = expectation(description: "Deadlock?")
        e.expectedFulfillmentCount = 500

        let queue = DispatchQueue(label: "TestSignal.Queue",
                                  qos: .userInitiated)

        for _ in 0..<e.expectedFulfillmentCount {

            let disposeBag = DisposeBag()

            var signalCallCount = 0

            let signal = Signal<Bool, Error> { observer in
                signalCallCount += 1

                queue.async { [signalCallCount] in
                    switch signalCallCount {
                    case 3:
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
                ).publish()
                return CompositeDisposable([signal.retry(when: trigger).observe(with: observer),
                                            trigger.connect()])
            }
            .observeNext {
                if $0 {
                    disposeBag.dispose()
                    e.fulfill()
                }
            }
            .dispose(in: disposeBag)
        }

        wait(for: [e], timeout: 8)
    }
}
