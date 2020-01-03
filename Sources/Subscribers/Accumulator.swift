//
//  The MIT License (MIT)
//
//  Copyright (c) 2020 Srdan Rasic (@srdanrasic)
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

extension Subscribers {

    /// A subscriber that accumulates received values into an array. This subscriber can be useful in unit testing by
    /// asserting the state of various properties of the subscriber.
    final public class Accumulator<Input, Failure: Swift.Error>: Subscriber, Cancellable {

        private enum State {
            case initialized
            case subscribed(Cancellable)
            case terminated(Completion<Failure>?)
        }

        private var state = State.initialized

        /// An array of values received by the subscriber.
        final public private(set) var values: [Input] = []

        /// True if the subscriber has received a finished event.
        final public var isFinished: Bool {
            switch state {
            case .terminated(.some(.finished)):
                return true
            default:
                return false
            }
        }

        /// True if the subscriber has received a failure event.
        final public var isFailure: Bool {
            switch state {
            case .terminated(.some(.failure)):
                return true
            default:
                return false
            }
        }

        /// Non-nil if the subscriber has received a failure event.
        final public var error: Failure? {
            switch state {
            case .terminated(.some(.failure(let error))):
                return error
            default:
                return nil
            }
        }
        
        
        public init() {
        }
        
        final public func receive(subscription: Subscription) {
            switch state {
            case .initialized:
                state = .subscribed(subscription)
                subscription.request(.unlimited)
            default:
                subscription.cancel()
            }
        }

        final public func receive(_ value: Input) -> Subscribers.Demand {
            values.append(value)
            return .unlimited
        }

        final public func receive(completion: Subscribers.Completion<Failure>) {
            switch state {
            case .terminated:
                break
            default:
                state = .terminated(completion)
            }
        }

        final public func cancel() {
            switch state {
            case .subscribed(let subscription):
                subscription.cancel()
                state = .terminated(nil)
            default:
                break
            }
        }
    }
}
