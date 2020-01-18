//
//  The MIT License (MIT)
//
//  Copyright (c) 2019 Srdan Rasic (@srdanrasic)
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

#if compiler(>=5.1)

import Foundation

/// A type of object with a publisher that emits before the object has changed.
///
/// By default an `ObservableObject` will synthesize an `objectWillChange`
/// publisher that emits before any of its `@Published` properties changes:
public protocol ObservableObject: AnyObject {

    /// The type of signal that emits before the object has changed.
    associatedtype ObjectWillChangeSignal: SignalProtocol = Signal<Void, Never> where Self.ObjectWillChangeSignal.Error == Never

    /// A signal that emits before the object has changed.
    var objectWillChange: Self.ObjectWillChangeSignal { get }
}

extension ObservableObject where Self.ObjectWillChangeSignal == Signal<Void, Never> {

    /// A publisher that emits before the object has changed.
    public var objectWillChange: Signal<Void, Never> {
        var signals: [Signal<Void, Never>] = []
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if var publishedProperty = child.value as? _MutablePropertyWrapper {
                signals.append(publishedProperty.willChange)
            }
        }
        return Signal(flattening: signals, strategy: .merge)
    }
}

#endif
