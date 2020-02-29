//
//  SignalProtocol+Timeline.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 29/02/2020.
//  Copyright © 2020 DeclarativeHub. All rights reserved.
//

import Foundation

public enum TimelineLaneType: Int, CaseIterable {
    case subscription, event
}

@available(macOS 10.14, iOS 12, tvOS 12, watchOS 5, *)
extension SignalProtocol {
    public func lane(_ name: String, filter: Set<TimelineLaneType> = Set(TimelineLaneType.allCases), file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> Signal<Element, Error> {
        
        let fileName = file.description.components(separatedBy: "/").last!
        let source = "\(fileName):\(line) - \(function)"
        let subscription = Timelane.Subscription(name: name)

        return handleEvents(
            receiveSubscription: {
                if filter.contains(.subscription) {
                    subscription.begin(source: source)
                }
            },
            receiveOutput: { (value) in
                if filter.contains(.event) {
                    subscription.event(value: .value(String(describing: value)), source: source)
                }
            },
            receiveCompletion: { (completion) in
                if filter.contains(.subscription) {
                    switch completion {
                    case .finished:
                        subscription.end(state: .completed)
                    case .failure(let error):
                        subscription.end(state: .error(error.localizedDescription))
                    }
                }
                if filter.contains(.event) {
                    switch completion {
                    case .finished:
                        subscription.event(value: .completion, source: source)
                    case .failure(let error):
                        subscription.event(value: .error(error.localizedDescription), source: source)
                    }
                }
            },
            receiveCancel: {
                if filter.contains(.subscription) {
                    subscription.end(state: .cancelled)
                }
                if filter.contains(.event) {
                    subscription.event(value: .cancelled, source: source)
                }
            }
        )
    }
}
