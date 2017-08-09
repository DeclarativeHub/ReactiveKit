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

/// A proxy protocol for reactive extensions.
///
/// To provide reactive extensions on type `X`, do
///
///     extension ReactiveExtensions where Base == X {
///       var y: SafeSignal<Int> { ... }
///     }
///
/// where `X` conforms to `ReactiveExtensionsProvider`.
public protocol ReactiveExtensions {
  associatedtype Base
  var base: Base { get }
}

public struct Reactive<Base>: ReactiveExtensions {
  public let base: Base

  public init(_ base: Base) {
    self.base = base
  }
}

public protocol ReactiveExtensionsProvider: class {}

public extension ReactiveExtensionsProvider {

  /// Reactive extensions of `self`.
  public var reactive: Reactive<Self> {
    return Reactive(self)
  }

  /// Reactive extensions of `Self`.
  public static var reactive: Reactive<Self>.Type {
    return Reactive<Self>.self
  }
}

extension NSObject: ReactiveExtensionsProvider {}

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)

  extension ReactiveExtensions where Base: NSObject {

    /// A signal that fires completion event when the object is deallocated.
    public var deallocated: SafeSignal<Void> {
      return base.bag.deallocated
    }

    /// A `DisposeBag` that can be used to dispose observations and bindings.
    public var bag: DisposeBag {
      return base.bag
    }
  }

#endif
