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

/// Represents a state as a stream of events.
public protocol PropertyType {
  associatedtype ProperyElement
  var value: ProperyElement { get }
}

/// Represents a state as a stream of events.
public final class Property<T>: PropertyType, StreamType, SubjectType {

  private var _value: T
  private let subject = PublishSubject<StreamEvent<T>>()
  private let lock = RecursiveLock(name: "ReactiveKit.Property")
  private let disposeBag = DisposeBag()

  public var rawStream: RawStream<StreamEvent<T>> {
    return subject.toRawStream().startWith(.Next(value))
  }

  /// Underlying value. Changing it emits `.Next` event with new value.
  public var value: T {
    get {
      return lock.atomic { _value }
    }
    set {
      lock.atomic {
        _value = newValue
        subject.next(newValue)
      }
    }
  }

  public func on(event: StreamEvent<T>) {
    if let element = event.element {
      self._value = element
    }
    subject.on(event)
  }

  public var readOnlyView: AnyProperty<T> {
    return AnyProperty(property: self)
  }

  public init(_ value: T) {
    _value = value
  }

  public func silentUpdate(value: T) {
    _value = value
  }

  deinit {
    subject.completed()
  }
}

public final class AnyProperty<T>: PropertyType, StreamType {

  private let property: Property<T>

  public var value: T {
    return property.value
  }

  public var rawStream: RawStream<StreamEvent<T>> {
    return property.rawStream
  }

  public init(property: Property<T>) {
    self.property = property
  }
}

extension Property: BindableType {
  
  /// Returns an observer that can be used to dispatch events to the receiver.
  /// Can accept a disposable that will be disposed on receiver's deinit.
  public func observer(disconnectDisposable: Disposable) -> StreamEvent<T> -> () {
    disposeBag.addDisposable(disconnectDisposable)
    return { [weak self] event in
      if let value = event.element {
        self?.value = value
      }
    }
  }
}
