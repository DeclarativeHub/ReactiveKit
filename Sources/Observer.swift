//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Srdan Rasic (@srdanrasic)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/// Represents a type that receives events.
public typealias Observer<Element, Error: Swift.Error> = (Event<Element, Error>) -> Void

/// Represents a type that receives events.
public protocol ObserverProtocol {

  /// Type of elements being received.
  associatedtype Element

  /// Type of error that can be received.
  associatedtype Error: Swift.Error

  /// Send the event to the observer.
  func on(_ event: Event<Element, Error>)
}

/// Represents a type that receives events. Observer is just a convenience
/// wrapper around a closure observer `Observer<Element, Error>`.
public struct AnyObserver<Element, Error: Swift.Error>: ObserverProtocol {

  private let observer: Observer<Element, Error>

  /// Creates an observer that wraps a closure observer.
  public init(observer: @escaping Observer<Element, Error>) {
    self.observer = observer
  }

  /// Calles wrapped closure with the given element.
  public func on(_ event: Event<Element, Error>) {
    observer(event)
  }
}

/// Observer that ensures events are sent atomically.
public class AtomicObserver<Element, Error: Swift.Error>: ObserverProtocol {

  private var observer: Observer<Element, Error>?
  private let lock = NSRecursiveLock(name: "com.reactivekit.signal.atomicobserver")
  private let parentDisposable: Disposable

  public private(set) var disposable: Disposable!

  /// Creates an observer that wraps given closure.
  public init(disposable: Disposable, observer: @escaping Observer<Element, Error>) {
    self.observer = observer
    self.parentDisposable = disposable
    self.disposable = BlockDisposable { [weak self] in
      self?.observer = nil
      disposable.dispose()
    }
  }

  /// Calles wrapped closure with the given element.
  public func on(_ event: Event<Element, Error>) {
    lock.lock(); defer { lock.unlock() }
    if let observer = observer {
      observer(event)
      if event.isTerminal {
        disposable.dispose()
      }
    }
  }
}

// MARK: - Extensions

public extension ObserverProtocol {

  /// Convenience method to send `.next` event.
  public func next(_ element: Element) {
    on(.next(element))
  }

  /// Convenience method to send `.failed` event.
  public func failed(_ error: Error) {
    on(.failed(error))
  }

  /// Convenience method to send `.completed` event.
  public func completed() {
    on(.completed)
  }

  /// Convenience method to send `.next` event followed by a `.completed` event.
  public func completed(with element: Element) {
    next(element)
    completed()
  }

  /// Converts the receiver to the Observer closure.
  public func toObserver() -> Observer<Element, Error> {
    return on
  }
}
