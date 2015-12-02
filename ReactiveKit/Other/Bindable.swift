//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Srdan Rasic (@srdanrasic)
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

public protocol BindableType {
  typealias Event
  
  /// Returns an observer that can be used to dispatch events to the receiver.
  /// Can accept a disposable that will be disposed on receiver's deinit.
  func observer(disconnectDisposable: DisposableType?) -> (Event -> ())
}

extension ActiveStream: BindableType {
  
  /// Creates a new observer that can be used to update the receiver.
  /// Optionally accepts a disposable that will be disposed on receiver's deinit.
  public func observer(disconnectDisposable: DisposableType?) -> Event -> () {
    
    if let disconnectDisposable = disconnectDisposable {
      registerDisposable(disconnectDisposable)
    }
    
    return { [weak self] value in
      self?.next(value)
    }
  }
}

extension StreamType {
  
  /// Establishes a one-way binding between the source and the bindable's observer
  /// and returns a disposable that can cancel observing.
  public func bindTo<B: BindableType where B.Event == Event>(bindable: B, context: ExecutionContext? = nil) -> DisposableType {
    let disposable = SerialDisposable(otherDisposable: nil)
    let observer = bindable.observer(disposable)
    disposable.otherDisposable = observe(on: context) { value in
      observer(value)
    }
    return disposable
  }
  
  /// Establishes a one-way binding between the source and the bindable's observer
  /// and returns a disposable that can cancel observing.
  public func bindTo<B: BindableType where B.Event == Event?>(bindable: B, context: ExecutionContext? = nil) -> DisposableType {
    let disposable = SerialDisposable(otherDisposable: nil)
    let observer = bindable.observer(disposable)
    disposable.otherDisposable = observe(on: context) { value in
      observer(value)
    }
    return disposable
  }
  
  /// Establishes a one-way binding between the source and the bindable's observer
  /// and returns a disposable that can cancel observing.
  public func bindTo<S: StreamType where S: BindableType, S.Event == Event>(bindable: S, context: ExecutionContext? = nil) -> DisposableType {
    let disposable = SerialDisposable(otherDisposable: nil)
    let observer = bindable.observer(disposable)
    disposable.otherDisposable = observe(on: context) { value in
      observer(value)
    }
    return disposable
  }
}

extension OperationType {
  
  public func bindNextTo<B: BindableType where B.Event == Value>(bindable: B, context: ExecutionContext? = nil) -> DisposableType {
    let disposable = SerialDisposable(otherDisposable: nil)
    let observer = bindable.observer(disposable)
    disposable.otherDisposable = observeNext(on: context) { value in
      observer(value)
    }
    return disposable
  }
  
  public func bindNextTo<B: BindableType where B.Event == Value?>(bindable: B, context: ExecutionContext? = nil) -> DisposableType {
    let disposable = SerialDisposable(otherDisposable: nil)
    let observer = bindable.observer(disposable)
    disposable.otherDisposable = observeNext(on: context) { value in
      observer(value)
    }
    return disposable
  }
}
