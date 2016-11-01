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

/// Represents mutable state that can be observed as a signal of events.
public protocol PropertyProtocol {
  associatedtype ProperyElement
  var value: ProperyElement { get }
}

/// Represents mutable state that can be observed as a signal of events.
public class Property<Value>: PropertyProtocol, SubjectProtocol, BindableProtocol {

  private var _value: Value
  private let subject = PublishSubject<Value, NoError>()
  private let lock = NSRecursiveLock(name: "com.reactivekit.property")

  public var disposeBag: DisposeBag {
    return subject.disposeBag
  }

  /// Underlying value. Changing it emits `.next` event with new value.
  public var value: Value {
    get {
      lock.lock(); defer { lock.unlock() }
      return _value
    }
    set {
      lock.lock(); defer { lock.unlock() }
      _value = newValue
      subject.next(newValue)
    }
  }

  public init(_ value: Value) {
    _value = value
  }

  public func on(_ event: Event<Value, NoError>) {
    if case .next(let element) = event {
      _value = element
    }
    subject.on(event)
  }

  public func observe(with observer: @escaping (Event<Value, NoError>) -> Void) -> Disposable {
    return subject.start(with: value).observe(with: observer)
  }

  public var readOnlyView: AnyProperty<Value> {
    return AnyProperty(property: self)
  }

  /// Change the underlying value withouth notifying the observers.
  public func silentUpdate(value: Value) {
    _value = value
  }

  public func bind(signal: Signal<Value, NoError>) -> Disposable {
    return signal
      .take(until: disposeBag.deallocated)
      .observeNext { [weak self] element in
        guard let s = self else { return }
        s.on(.next(element))
      }
  }

  deinit {
    subject.completed()
  }
}

/// Represents mutable state that can be observed as a signal of events.
public final class AnyProperty<Value>: PropertyProtocol, SignalProtocol {

  private let property: Property<Value>

  public var value: Value {
    return property.value
  }

  public init(property: Property<Value>) {
    self.property = property
  }

  public func observe(with observer: @escaping (Event<Value, NoError>) -> Void) -> Disposable {
    return property.observe(with: observer)
  }
}
