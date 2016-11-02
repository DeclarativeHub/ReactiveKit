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

/// A Signal represents a stream of elements.
public struct Signal<Element, Error: Swift.Error>: SignalProtocol {

  public typealias Producer = (AtomicObserver<Element, Error>) -> Disposable
  private let producer: Producer

  /// Create new signal given a producer closure.
  public init(producer: @escaping Producer) {
    self.producer = producer
  }

  /// Register the observer that will receive events from the signal.
  public func observe(with observer: @escaping (Event<Element, Error>) -> Void) -> Disposable {
    let serialDisposable = SerialDisposable(otherDisposable: nil)
    let observer = AtomicObserver(disposable: serialDisposable, observer: observer)
    serialDisposable.otherDisposable = producer(observer)
    return serialDisposable
  }

  public func toSignal() -> Signal<Element, Error> {
    return self
  }
}

/// A convenience alias for non-failable signals.
public typealias Signal1<Element> = Signal<Element, NoError>
