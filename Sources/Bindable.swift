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

/// Bindable is like an observer, but knows to manage the subscription by itself.
public protocol BindableProtocol {

  /// Type of the received elements.
  associatedtype Element

  /// Establish a one-way binding between the signal and the receiver.
  /// - Warning: Do not use this method to bind signals. Use `bind(to:)` instead.
  func bind(signal: Signal<Element, NoError>) -> Disposable
}

extension SignalProtocol where Error == NoError {

  /// Establish a one-way binding between the source and the bindable.
  /// - Parameter bindable: A binding target that will receive signal events.
  /// - Parameter context: An execution context used to delived events. 
  ///     Defaults to a context that breaks recursive calls.
  /// - Returns: A disposable that can cancel the binding.
  @discardableResult
  public func bind<B: BindableProtocol>(to bindable: B, context: @escaping ExecutionContext = createNonRecursiveContext()) -> Disposable where B.Element == Element {
    return bindable.bind(signal: observeIn(context))
  }

  /// Establish a one-way binding between the source and the bindable.
  /// - Parameter bindable: A binding target that will receive signal events.
  /// - Parameter context: An execution context used to delived events. 
  ///     Defaults to a context that breaks recursive calls.
  /// - Returns: A disposable that can cancel the binding.
  @discardableResult
  public func bind<B: BindableProtocol>(to bindable: B, context: @escaping ExecutionContext = createNonRecursiveContext()) -> Disposable where B.Element: OptionalProtocol, B.Element.Wrapped == Element {
    return map { B.Element($0) }.observeIn(context).bind(to: bindable)
  }
}

extension BindableProtocol where Self: SignalProtocol, Self.Error == NoError {

  /// Establish a two-way binding between the source and the bindable.
  /// - Parameter target: A binding target that will receive events from
  ///     the receiver and a source that will send events to the receiver.
  /// - Parameter context: An execution context used to delived events.
  ///     Defaults to a context that breaks recursive calls.
  /// - Returns: A disposable that can cancel the binding.
  @discardableResult
  public func bidirectionalBind<B: BindableProtocol & SignalProtocol>(to target: B, context: @escaping ExecutionContext = createNonRecursiveContext()) -> Disposable where B.Element == Element, B.Error == Error {
    let d1 = bind(to: target, context: context)
    let d2 = target.bind(to: self, context: context)
    return CompositeDisposable([d1, d2])
  }
}

extension SignalProtocol where Error == NoError {

  /// Bind the receiver to the target using the given setter closure. Closure is
  /// called whenever the signal emits `next` event.
  ///
  /// Binding lives until either the signal completes or the target is deallocated.
  /// That means that the returned disposable can be safely ignored.
  ///
  /// - Parameters:
  ///   - target: A binding target. Conforms to `Deallocatable` so it can inform the binding
  ///  when it gets deallocated. Upon target deallocation, the binding gets automatically disposed.
  /// Also conforms to `BindingExecutionContextProvider` that provides that context on which to execute the setter.
  ///   - setter: A closure that gets called on each next signal event both with the target and the sent element.
  /// - Returns: A disposable that can cancel the binding.
  @discardableResult
  public func bind<Target: Deallocatable>(to target: Target, setter: @escaping (Target, Element) -> Void) -> Disposable
  where Target: BindingExecutionContextProvider
  {
    return bind(to: target, context: target.bindingExecutionContext, setter: setter)
  }

  /// Bind the receiver to the target using the given setter closure. Closure is
  /// called whenever the signal emits `next` event.
  ///
  /// Binding lives until either the signal completes or the target is deallocated.
  /// That means that the returned disposable can be safely ignored.
  ///
  /// - Parameters:
  ///   - target: A binding target. Conforms to `Deallocatable` so it can inform the binding
  ///  when it gets deallocated. Upon target deallocation, the binding gets automatically disposed.
  ///   - context: An execution context on which to execute the setter.
  ///   - setter: A closure that gets called on each next signal event both with the target and the sent element.
  /// - Returns: A disposable that can cancel the binding.
  @discardableResult
  public func bind<Target: Deallocatable>(to target: Target, context: @escaping ExecutionContext, setter: @escaping (Target, Element) -> Void) -> Disposable {
      return take(until: target.deallocated).observeNext { [weak target] element in
        context {
          if let target = target {
            setter(target, element)
          }
        }
      }
  }
}

/// Provides an execution context used to deliver binding events.
///
/// `NSObject` conforms to this protocol be providing `ImmediateOnMainExecutionContext`
/// as binding execution context. Specific subclasses can override the context if needed.
public protocol BindingExecutionContextProvider {

  /// An execution context used to deliver binding events.
  var bindingExecutionContext: ExecutionContext { get }
}

extension NSObject: BindingExecutionContextProvider {

  public var bindingExecutionContext: ExecutionContext {
    return ImmediateOnMainExecutionContext
  }
}

/// A context that breaks recursive calls (binding cycles).
private func createNonRecursiveContext() -> ExecutionContext {
  var updating = false
  return { block in
    guard !updating else { return }
    updating = true
    block()
    updating = false
  }
}
