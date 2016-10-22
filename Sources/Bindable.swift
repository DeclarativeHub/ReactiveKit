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

/// Bindable is like an observer, but knows to manage the subscription by itself.
public protocol BindableProtocol {

  associatedtype Element

  /// Accepts a signal that should be observed by the receiver.
  func bind(signal: Signal<Element, NoError>) -> Disposable
}

extension SignalProtocol where Error == NoError {

  /// Establish a one-way binding between the source and the bindable
  /// and return a disposable that can cancel binding.
  @discardableResult
  public func bind<B: BindableProtocol>(to bindable: B, context: @escaping ExecutionContext = createNonRecursiveContext()) -> Disposable where B.Element == Element {
    return bindable.bind(signal: observeIn(context))
  }

  /// Establish a one-way binding between the source and the bindable
  /// and return a disposable that can cancel binding.
  @discardableResult
  public func bind<B: BindableProtocol>(to bindable: B, context: @escaping ExecutionContext = createNonRecursiveContext()) -> Disposable where B.Element: OptionalProtocol, B.Element.Wrapped == Element {
    return map { B.Element($0) }.observeIn(context).bind(to: bindable)
  }
}

extension BindableProtocol where Self: SignalProtocol, Self.Error == NoError {

  /// Establish a two-way binding between the source and the bindable
  /// and return a disposable that can cancel binding.
  @discardableResult
  public func bidirectionalBind<B: BindableProtocol & SignalProtocol>(to bindable: B, context: @escaping ExecutionContext = createNonRecursiveContext()) -> Disposable where B.Element == Element, B.Error == Error {
    let d1 = bind(to: bindable, context: context)
    let d2 = bindable.bind(to: self, context: context)
    return CompositeDisposable([d1, d2])
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
