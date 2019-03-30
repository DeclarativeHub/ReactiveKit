//
//  The MIT License (MIT)
//
//  Copyright (c) 2016-2019 Srdan Rasic (@srdanrasic)
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

extension SignalProtocol {

    /// Log various signal events. If title is not provided, source file and function names are printed instead.
    public func debug(_ title: String? = nil, file: String = #file, function: String = #function, line: Int = #line) -> Signal<Element, Error> {
        let prefix: String
        if let title = title {
            prefix = "[\(title)]"
        } else {
            let filename = file.components(separatedBy: "/").last ?? file
            prefix = "[\(filename):\(function):\(line)]"
        }
        return doOn(next: { element in
            print("\(prefix) next(\(element))")
        }, start: {
            print("\(prefix) started")
        }, failed: { error in
            print("\(prefix) failed: \(error)")
        }, completed: {
            print("\(prefix) completed")
        }, disposed: {
            print("\(prefix) disposed")
        })
    }
    
    /// Delay signal elements for `interval` time.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#delay](https://rxmarbles.com/#delay)
    public func delay(interval: Double, on queue: DispatchQueue = DispatchQueue(label: "reactive_kit.delay")) -> Signal<Element, Error> {
        return Signal { observer in
            return self.observe { event in
                queue.after(when: interval) {
                    observer.on(event)
                }
            }
        }
    }

    /// Do side-effect upon various events.
    public func doOn(next: ((Element) -> ())? = nil,
                     start: (() -> Void)? = nil,
                     failed: ((Error) -> Void)? = nil,
                     completed: (() -> Void)? = nil,
                     disposed: (() -> ())? = nil) -> Signal<Element, Error> {
        return Signal { observer in
            start?()
            let disposable = self.observe { event in
                switch event {
                case .next(let value):
                    next?(value)
                case .failed(let error):
                    failed?(error)
                case .completed:
                    completed?()
                }
                observer.on(event)
            }
            return BlockDisposable {
                disposable.dispose()
                disposed?()
            }
        }
    }

    /// Update the given subject with `true` when the receiver starts and with `false` when the receiver terminates.
    public func feedActivity<S: SubjectProtocol>(into listener: S) -> Signal<Element, Error> where S.Element == Bool {
        return doOn(start: { listener.next(true) }, disposed: { listener.next(false) })
    }

    /// Update the given subject with `.next` elements.
    public func feedNext<S: SubjectProtocol>(into listener: S) -> Signal<Element, Error> where S.Element == Element {
        return doOn(next: { e in listener.next(e) })
    }

    /// Update the given subject with mapped `.next` element whenever the element satisfies the given constraint.
    public func feedNext<S: SubjectProtocol>(into listener: S, when: @escaping (Element) -> Bool = { _ in true }, map: @escaping (Element) -> S.Element) -> Signal<Element, Error> {
        return doOn(next: { e in if when(e) { listener.next(map(e)) } })
    }

    /// Updates the given subject with error from .failed event is such occurs.
    public func feedError<S: SubjectProtocol>(into listener: S) -> Signal<Element, Error> where S.Element == Error {
        return doOn(failed: { e in listener.next(e) })
    }
}
