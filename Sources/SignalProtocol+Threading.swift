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

    /// Set the scheduler on which to execute the signal (i.e. to run the signal's producer).
    ///
    /// In contrast with `receive(on:)`, which affects downstream actions, `subscribe(on:)` changes the execution context of upstream actions.
    public func subscribe<S: Scheduler>(on scheduler: S) -> Signal<Element, Error> {
        return Signal { observer in
            let serialDisposable = SerialDisposable(otherDisposable: nil)
            scheduler.schedule {
                if !serialDisposable.isDisposed {
                    serialDisposable.otherDisposable = self.observe(with: observer.on)
                }
            }
            return serialDisposable
        }
    }

    /// Set the scheduler used to receive events (i.e. to run the observer / sink).
    ///
    /// In contrast with `subscribe(on:)`, which affects upstream actions, `receive(on:)` changes the execution context of downstream actions.
    public func receive<S: Scheduler>(on scheduler: S) -> Signal<Element, Error> {
        return Signal { observer in
            return self.observe { event in
                scheduler.schedule {
                    observer.on(event)
                }
            }
        }
    }
}
