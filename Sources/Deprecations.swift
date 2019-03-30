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

import Dispatch
import Foundation

@available(*, deprecated, renamed: "Never")
public typealias NoError = Never

@available(*, deprecated, renamed: "SafeSignal")
public typealias Signal1<Element> = Signal<Element, Never>

@available(*, deprecated, renamed: "SafeObserver")
public typealias Observer1<Element> = (Event<Element, Never>) -> Void

@available(*, deprecated, renamed: "SafePublishSubject")
public typealias PublishSubject1<Element> = PublishSubject<Element, Never>

@available(*, deprecated, renamed: "SafeReplaySubject")
public typealias ReplaySubject1<Element> = ReplaySubject<Element, Never>

@available(*, deprecated, renamed: "SafeReplayOneSubject")
public typealias ReplayOneSubject1<Element> = ReplayOneSubject<Element, Never>

extension SignalProtocol {

    @available(*, deprecated, renamed: "init(just:)")
    public static func just(_ element: Element) -> Signal<Element, Error> {
        return Signal(just: element)
    }

    @available(*, deprecated, renamed: "init(sequence:)")
    public static func sequence<S: Sequence>(_ sequence: S) -> Signal<Element, Error> where S.Iterator.Element == Element {
        return Signal(sequence: sequence)
    }

    @available(*, deprecated, message: "Please use Signal(sequence: 0..., interval: N) instead")
    public static func interval(_ interval: Double, queue: DispatchQueue = DispatchQueue(label: "com.reactivekit.interval")) -> Signal<Int, Error> {
        return Signal(sequence: 0..., interval: interval, queue: queue)
    }

    @available(*, deprecated, message: "Please use Signal(just:after:) instead")
    public static func timer(element: Element, time: Double, queue: DispatchQueue = DispatchQueue(label: "com.reactivekit.timer")) -> Signal<Element, Error> {
        return Signal(just: element, after: time, queue: queue)
    }
}

@available(*, deprecated, message: "Please use Signal(flattening: signals, strategy: .merge")
public func merge<Element, Error>(_ signals: [Signal<Element, Error>]) -> Signal<Element, Error> {
    return Signal(sequence: signals).flatten(.merge)
}

@available(*, deprecated, renamed: "Signal(combiningLatest:combine:)")
public func combineLatest<Element, Result, Error>(_ signals: [Signal<Element, Error>], combine: @escaping ([Element]) -> Result) -> Signal<Result, Error> {
    return Signal(combiningLatest: signals, combine: combine)
}

extension SignalProtocol where Element: OptionalProtocol {

    @available(*, deprecated, renamed: "replaceNils")
    public func replaceNil(with replacement: Element.Wrapped) -> Signal<Element.Wrapped, Error> {
        return replaceNils(with: replacement)
    }

    @available(*, deprecated, renamed: "ignoreNils")
    public func ignoreNil() -> Signal<Element.Wrapped, Error> {
        return ignoreNils()
    }
}

extension Signal where Error == Never {

    @available(*, deprecated, message: "Replace with compactMap { $0.element }`")
    public func elements<U, E>() -> Signal<U, Never> where Element == Event<U, E> {
        return compactMap { $0.element }
    }

    @available(*, deprecated, message: "Replace with compactMap { $0.error }`")
    public func errors<U, E>() -> Signal<E, Never> where Element == Event<U, E> {
        return compactMap { $0.error }
    }
}

extension SignalProtocol {

    @available(*, deprecated, renamed: "debounce(interval:queue:)")
    public func debounce(interval: Double, on queue: DispatchQueue) -> Signal<Element, Error> {
        return debounce(interval: interval, queue: queue)
    }

    @available(*, deprecated, renamed: "distinctUntilChanged")
    public func distinct(areDistinct: @escaping (Element, Element) -> Bool) -> Signal<Element, Error> {
        return distinctUntilChanged(areDistinct)
    }

    @available(*, deprecated, renamed: "replaceElements")
    public func replace<T>(with element: T) -> Signal<T, Error> {
        return replaceElements(with: element)
    }
}

extension SignalProtocol where Element: Equatable {

    @available(*, deprecated, renamed: "distinctUntilChanged")
    public func distinct() -> Signal<Element, Error> {
        return distinctUntilChanged()
    }
}
