//
//  Empty.swift
//  ReactiveKit-iOS
//
//  Created by Ibrahim Koteish on 06/03/2020.
//  Copyright © 2020 DeclarativeHub. All rights reserved.
//

import Foundation

/// A signal that never publishes any values, and optionally finishes immediately.
///
/// You can create a ”Never” signal — one which never sends values and never
/// finishes or fails — with the initializer `Empty(completeImmediately: false)`.
public struct Empty<Element, Error: Swift.Error>: SignalProtocol, Equatable {

    /// The kind of values published by this signal.
    public typealias Element = Element
    
    /// The kind of errors this signal might publish.
    ///
    /// Use `Never` if this `signal` does not publish errors.
    public typealias Error = Error
    
    /// Creates an empty signal.
    ///
    /// - Parameter completeImmediately: A Boolean value that indicates whether
    ///   the signal should immediately finish.
    public init(completeImmediately: Bool = true) {
        self.completeImmediately = completeImmediately
    }
    
    /// Creates an empty signal with the given completion behavior and output and
    /// failure types.
    ///
    /// Use this initializer to connect the empty signal to observers or other
    /// signals that have specific output and failure types.
    /// - Parameters:
    ///   - completeImmediately: A Boolean value that indicates whether the signal
    ///     should immediately finish.
    ///   - outputType: The output type exposed by this signal.
    ///   - failureType: The failure type exposed by this signal.
    public init(completeImmediately: Bool = true,
                outputType: Element.Type,
                failureType: Error.Type) {
        self.init(completeImmediately: completeImmediately)
    }
    
    /// A Boolean value that indicates whether the signal immediately sends
    /// a completion.
    ///
    /// If `true`, the signal finishes immediately after sending an event
    /// to the observer. If `false`, it never completes.
    public let completeImmediately: Bool
    
    public func observe(with observer: @escaping (Signal<Element, Error>.Event) -> Void) -> Disposable {
        
        if completeImmediately {
            return Signal<Element, Error>.completed().observe(with: observer)
        }
        return Signal<Element, Error>.never().observe(with: observer)
    }
}
