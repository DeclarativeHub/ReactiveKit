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
  associatedtype Error: Swift.Error

  /// Accepts a signal that should be observed by the receiver.
  func bind(signal: Signal<Element, Error>) -> Disposable
}

extension SignalProtocol {

  /// Establish a one-way binding between the source and the bindable
  /// and return a disposable that can cancel binding.
  @discardableResult
  public func bind<B: BindableProtocol>(to bindable: B) -> Disposable where B.Element == Element, B.Error == Error {
    return bindable.bind(signal: filterRecursiveEvents())
  }

  /// Establish a one-way binding between the source and the bindable
  /// and return a disposable that can cancel binding.
  @discardableResult
  public func bind<B: BindableProtocol>(to bindable: B) -> Disposable where B.Element: OptionalProtocol, B.Element.Wrapped == Element, B.Error == Error {
    return self.map { B.Element($0) }.bind(to: bindable)
  }
}

extension BindableProtocol where Self: SignalProtocol {

  /// Establish a two-way binding between the source and the bindable
  /// and return a disposable that can cancel binding.
  @discardableResult
  public func bidirectionalBind<B: BindableProtocol >(to bindable: B) -> Disposable where B: SignalProtocol, B.Element == Element, B.Error == Error {
    let d1 = self.bind(to: bindable)
    let d2 = bindable.bind(to: self)
    return CompositeDisposable([d1, d2])
  }
}
