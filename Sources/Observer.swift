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

/// Represents a type that receives events.
public protocol ObserverType {

  /// Type of events being received.
  associatedtype Event: EventType

  /// Sends given event to the observer.
  func on(event: Event)
}

/// Represents a type that receives events. Observer is just a convenience
/// wrapper around a closure that accepts an event of EventType.
public struct Observer<Event: EventType>: ObserverType {

  internal let observer: Event -> Void

  /// Creates an observer that wraps given closure.
  public init(observer: Event -> Void) {
    self.observer = observer
  }

  /// Calles wrapped closure with given element.
  public func on(event: Event) {
    observer(event)
  }
}

// MARK: - Extensions

public extension ObserverType {

  /// Convenience method to send `.Next` event.
  public func next(element: Event.Element) {
    on(.next(element))
  }
  
  /// Convenience method to send `.Completed` event.
  public func completed() {
    on(.completed())
  }
}

public extension ObserverType where Event: Errorable {

  /// Convenience method to send `.Failure` event.
  public func failure(error: Event.Error) {
    on(.failure(error))
  }
}

public final class ObserverWith<O: AnyObject, T>: ObserverType, BindableType {
  weak var object: O?
  let observer: (O, T) -> Void
  public let disposeBag = DisposeBag()

  public init(_ object: O, observer: (O, T) -> Void) {
    self.object = object
    self.observer = observer
  }

  public func on(event: StreamEvent<T>) {
    if case .Next(let element) = event, let object = object {
      observer(object, element)
    } else {
      disposeBag.dispose()
    }
  }

  public func observer(disconnectDisposable: Disposable) -> (StreamEvent<T> -> Void) {
    disconnectDisposable.disposeIn(disposeBag)
    return self.on
  }
}
