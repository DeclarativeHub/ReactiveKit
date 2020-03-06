//
//  Deferred.swift
//  GlovoCourier
//
//  Created by Ibrahim Koteish on 01/12/2019.
//  Copyright © 2019 Glovo. All rights reserved.
//

import Foundation

/// A signal that awaits subscription before running the supplied closure
/// to create a signal for the new subscriber.
public struct Deferred<DeferredSignal: SignalProtocol>: SignalProtocol {
  
    /// The kind of values published by this signal.
    public typealias Element = DeferredSignal.Element

    /// The kind of errors this signal might publish.
    ///
    /// Use `Never` if this `signal` does not publish errors.
    public typealias Error = DeferredSignal.Error

    /// The closure to execute when it receives a subscription.
    ///
    /// The signal returned by this closure immediately
    /// receives the incoming subscription.
    public let signalFactory: () -> DeferredSignal

    /// Creates a deferred signal.
    ///
    /// - Parameter signalFactory: The closure to execute
    /// when calling `observe(with:)`.
    public init(signalFactory: @escaping () -> DeferredSignal) {
        self.signalFactory = signalFactory
    }
  
  /// This function is called to attach the specified `Observer`
  /// to this `Signal` by `observe(with:)`
  ///
  /// - Parameters:
  ///       - observer: The observer to attach to this `Signal`.
  ///                once attached it can begin to receive values.
  public func observe(
    with observer: @escaping (Signal<DeferredSignal.Element, DeferredSignal.Error>.Event) -> Void)
    -> Disposable
  {
    let deferredSignal = signalFactory()
    return deferredSignal.observe(with: observer)
  }
}
