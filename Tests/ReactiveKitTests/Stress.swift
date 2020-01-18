//
//  Common.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 14/04/16.
//  Copyright © 2016 Srdan Rasic. All rights reserved.
//

import XCTest
import ReactiveKit

extension SignalProtocol {

    func stress(
        with sendElements: [(Int) -> Void],
        queuesCount: Int = 3,
        eventsCount: Int = 3000,
        timeout: Double = 2,
        expectation: XCTestExpectation
    ) -> Disposable {
        
        let dispatchQueues = Array((0..<queuesCount).map { DispatchQueue(label: "queue_\($0)") })
        let disposeBag = DisposeBag()
        
        dispatchQueues.first?.async {
            self.observe { _ in }.dispose(in: disposeBag)
        }
        
        for eventIndex in 0..<eventsCount {
            for (offset, sendElement) in sendElements.enumerated() {
                dispatchQueues[(eventIndex + offset + 1) % queuesCount].async {
                    sendElement(eventIndex)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            expectation.fulfill()
        }
        
        return disposeBag
    }
    
    func stress<S: SubjectProtocol>(
        with subjects: [S],
        queuesCount: Int = 3,
        eventsCount: Int = 3000,
        timeout: Double = 2,
        expectation: XCTestExpectation
    ) -> Disposable where S.Element == Int {
        return stress(
            with: subjects.map { subject in { event in subject.send(event) } },
            queuesCount: queuesCount,
            eventsCount: eventsCount,
            timeout: timeout,
            expectation: expectation
        )
    }
}


