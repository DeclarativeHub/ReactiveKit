//
//  TestObservers.swift
//  GlovoCourierTests
//
//  Created by Ibrahim Koteish on 15/12/2019.
//  Copyright © 2019 Glovo. All rights reserved.
//

import XCTest
import ReactiveKit

public extension Signal.Event {
    var isValue: Bool {
        return self.element != nil
    }
    
    var isFailed: Bool {
        return self.error != nil
    }
    
    /// Return `true` in case of `.failure` or `.completed` event.
    var isCompleted: Bool {
        switch self {
        case .completed:
            return true
        default:
            return false
        }
    }
}

// Assert equality between two doubly nested arrays of equatables.
public func XCTAssertEqual<T: Equatable>(
    _ expression1: @autoclosure () -> [[T]],
    _ expression2: @autoclosure () -> [[T]],
    _ message: String = "",
    file: StaticString = #file,
    line: UInt = #line)
{
    let lhs = expression1()
    let rhs = expression2()
    XCTAssertEqual(lhs.count, rhs.count, "Expected \(lhs.count) elements, but found \(rhs.count).",
        file: file, line: line)
    
    zip(lhs, rhs).forEach { xs, ys in
        XCTAssertEqual(xs, ys, "Expected \(lhs), but found \(rhs): \(message)", file: file, line: line)
    }
}

// Assert equality between arrays of optionals of equatables.
public func XCTAssertEqual <T: ReactiveKit.OptionalProtocol>(
    _ expression1: [T],
    _ expression2: [T],
    _ message: String = "",
    file: StaticString = #file,
    line: UInt = #line)
    where T.Wrapped: Equatable
{
    XCTAssertEqual(
        expression1.count, expression2.count,
        "Expected \(expression1.count) elements, but found \(expression2.count).",
        file: file, line: line
    )
    
    zip(expression1, expression2).forEach { (arg) in
        let (xs, ys) = arg
        XCTAssertEqual(
            xs._unbox, ys._unbox,
            "Expected \(expression1), but found \(expression2): \(message)",
            file: file, line: line
        )
    }
}

/// An Observer is a simple wrapper around a function which can receive Events
/// (typically from a Signal).
public final class Observer<Value, Error: Swift.Error>: ObserverProtocol {
    public typealias Error = Error
    
    public typealias Element = Value
    
    public typealias Action = (Signal<Element, Error>.Event) -> Void
    
    /// An action that will be performed upon arrival of the event.
    public let action: Action
    
    /// An initializer that accepts a closure accepting an event for the
    /// observer.
    ///
    /// - parameters:
    ///   - action: A closure to lift over received event.
    public init(_ action: @escaping Action) {
        self.action = action
    }
    
    /// An initializer that accepts closures for different event types.
    ///
    /// - parameters:
    ///   - value: Optional closure executed when a `value` event is observed.
    ///   - failed: Optional closure that accepts an `Error` parameter when a
    ///             failed event is observed.
    ///   - completed: Optional closure executed when a `completed` event is
    ///                observed.
    public convenience init(
        value: ((Value) -> Void)? = nil,
        failed: ((Error) -> Void)? = nil,
        completed: (() -> Void)? = nil)
    {
        self.init { event in
            switch event {
            case let .next(v):
                value?(v)
                
            case let .failed(error):
                failed?(error)
                
            case .completed:
                completed?()
            }
        }
    }
    
    public func on(_ event: Signal<Element, Error>.Event) {
        action(event)
    }
    
    /// Puts a `value` event into `self`.
    ///
    /// - parameters:
    ///   - value: A value sent with the `value` event.
    public func send(value: Value) {
        action(.next(value))
    }
    
    /// Puts a failed event into `self`.
    ///
    /// - parameters:
    ///   - error: An error object sent with failed event.
    public func send(error: Error) {
        action(.failed(error))
    }
    
    /// Puts a `completed` event into `self`.
    public func sendCompleted() {
        action(.completed)
    }
}

/**
 A `TestObserver` is a wrapper around an `Observer` that saves all events to an public array so that
 assertions can be made on a signal's behavior. To use, just create an instance of `TestObserver` that
 matches the type of signal/producer you are testing, and observer/start your signal by feeding it the
 wrapped observer. For example,
 
 ```
 let test = TestObserver<Int, Never>()
 mySignal.observer(test.observer)
 
 // ... later ...
 
 test.assertValues([1, 2, 3])
 ```
 */

public final class TestObserver <Value, Error: Swift.Error> {
    
    public private(set) var events: [Signal<Value, Error>.Event] = []
    public private(set) var observer: Observer<Value, Error>!
    
    public init() {
        self.observer = Observer<Value, Error>(action)
    }
    
    private func action(_ event: Signal<Value, Error>.Event) {
        self.events.append(event)
    }
    
    /// Get all of the next values emitted by the signal.
    public var values: [Value] {
        return self.events.filter { $0.isValue }.map { $0.element! }
    }
    
    /// Get the last value emitted by the signal.
    public var lastValue: Value? {
        return self.values.last
    }
    
    /// `true` if at least one `.Next` value has been emitted.
    public var didEmitValue: Bool {
        return self.values.count > 0
    }
    
    /// The failed error if the signal has failed.
    public var failedError: Error? {
        return self.events.filter { $0.isFailed }.map { $0.error! }.first
    }
    
    /// `true` if a `.Failed` event has been emitted.
    public var didFail: Bool {
        return self.failedError != nil
    }
    
    /// `true` if a `.Completed` event has been emitted.
    public var didComplete: Bool {
        return self.events.filter { $0.isCompleted }.count > 0
    }
    
    public func assertDidComplete(
        _ message: String = "Should have completed.",
        file: StaticString = #file,
        line: UInt = #line)
    {
        XCTAssertTrue(self.didComplete, message, file: file, line: line)
    }
    
    public func assertDidFail(
        _ message: String = "Should have failed.",
        file: StaticString = #file,
        line: UInt = #line)
    {
        XCTAssertTrue(self.didFail, message, file: file, line: line)
    }
    
    public func assertDidNotFail(
        _ message: String = "Should not have failed.",
        file: StaticString = #file,
        line: UInt = #line)
    {
        XCTAssertFalse(self.didFail, message, file: file, line: line)
    }
    
    public func assertDidNotComplete(
        _ message: String = "Should not have completed",
        file: StaticString = #file,
        line: UInt = #line) {
        XCTAssertFalse(self.didComplete, message, file: file, line: line)
    }
    
    public func assertDidEmitValue(
        _ message: String = "Should have emitted at least one value.",
        file: StaticString = #file,
        line: UInt = #line)
    {
        XCTAssert(self.values.count > 0, message, file: file, line: line)
    }
    
    public func assertDidNotEmitValue(
        _ message: String = "Should not have emitted any values.",
        file: StaticString = #file,
        line: UInt = #line)
    {
        XCTAssertEqual(0, self.values.count, message, file: file, line: line)
    }
    
    public func assertDidTerminate(
        _ message: String = "Should have terminated, i.e. completed/failed.",
        file: StaticString = #file,
        line: UInt = #line)
    {
        XCTAssertTrue(self.didFail || self.didComplete, message, file: file, line: line)
    }
    
    public func assertDidNotTerminate(
        _ message: String = "Should not have terminated, i.e. completed/failed.",
        file: StaticString = #file,
        line: UInt = #line)
    {
        XCTAssertTrue(!self.didFail && !self.didComplete, message, file: file, line: line)
    }
    
    public func assertValueCount(
        _ count: Int,
        _ message: String? = nil,
        file: StaticString = #file,
        line: UInt = #line)
    {
        XCTAssertEqual(
            count,
            self.values.count,
            message ?? "Should have emitted \(count) values",
            file: file,
            line: line
        )
    }
    
    public func assertValue(
        _ message: String? = "Function evaluation failed",
        file: StaticString = #file,
        line: UInt = #line,
        _ evaluate: (Value) -> Bool)
    {
        XCTAssertEqual(1, self.values.count, "A single item should have been emitted.", file: file, line: line)
        if let value = self.lastValue {
            XCTAssertTrue(evaluate(value), message ?? "Function evaluation failed", file: file, line: line)
        }
    }
    
    public func assertLastValue(
        _ message: String? = "Function evaluation failed",
        file: StaticString = #file,
        line: UInt = #line,
        _ evaluate: (Value) -> Bool)
    {
        if let value = self.lastValue {
            XCTAssertTrue(evaluate(value), message ?? "Function evaluation failed", file: file, line: line)
        } else {
            XCTAssertTrue(false, message ?? "Function evaluation failed" + " - Missing Value", file: file, line: line)
        }
    }
}

public extension TestObserver where Value: Equatable {
    func assertValue(
        _ value: Value,
        _ message: String? = nil,
        file: StaticString = #file,
        line: UInt = #line)
    {
        XCTAssertEqual(1, self.values.count, "A single item should have been emitted.", file: file, line: line)
        XCTAssertEqual(value, self.lastValue, message ?? "A single value of \(value) should have been emitted",
            file: file, line: line)
    }
    
    func assertLastValue(
        _ value: Value,
        _ message: String? = nil,
        file: StaticString = #file,
        line: UInt = #line)
    {
        XCTAssertEqual(value, self.lastValue, message ?? "Last emitted value is equal to \(value).",
            file: file, line: line)
    }
    @discardableResult
    func assertValues(
        _ values: [Value],
        _ message: String = "",
        file: StaticString = #file,
        line: UInt = #line) -> String
    {
        let isTrue = values == self.values
        XCTAssertEqual(values, self.values, message, file: file, line: line)
        return isTrue ? "✅" : "❌ \(values) != \(self.values)"
    }
    
    @discardableResult
    func assertDidCompleteWithValues(
        _ values: [Value],
        _ message: String = "",
        file: StaticString = #file,
        line: UInt = #line) -> String
    {
        let isTrue = values == self.values
        XCTAssertEqual(values, self.values, message, file: file, line: line)
        XCTAssertTrue(self.didComplete)
        return isTrue ? "✅" : "❌ \(values) != \(self.values)"
    }
}
extension TestObserver where Error: Equatable {
    public func assertFailed(
        _ expectedError: Error,
        message: String = "",
        file: StaticString = #file,
        line: UInt = #line)
    {
        XCTAssertEqual(expectedError, self.failedError, message, file: file, line: line)
    }
}
