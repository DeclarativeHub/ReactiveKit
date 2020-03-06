//
// MIT License
//
// Copyright (c) 2020 Marin Todorov
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// This file is taken directly from https://github.com/icanzilb/TimelaneCore/
// in accordance with the MIT licence and author's approval. Thanks Marin!

import Foundation
import os

@available(macOS 10.14, iOS 12, tvOS 12, watchOS 5, *)
internal class Timelane {

    static let version = 1
    static var log: OSLog = {
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            return OSLog(subsystem: "tools.timelane.subscriptions", category: OSLog.Category.dynamicStackTracing)
        } else {
            // Fallback on a hardcoded category name.
            return OSLog(subsystem: "tools.timelane.subscriptions", category: "DynamicStackTracing")
        }
    }()
    public class Subscription {

        private static var subscriptionCounter: UInt64 = 0
        private static var lock = NSRecursiveLock()

        private let subscriptionID: UInt64
        private let name: String

        public init(name: String? = nil) {
            Self.lock.lock()
            Self.subscriptionCounter += 1
            subscriptionID = Self.subscriptionCounter
            Self.lock.unlock()

            if let name = name {
                self.name = name
            } else {
                self.name = "subscription-\(subscriptionID)"
            }
        }

        public func begin(source: String = "") {
            _ = Self.emitVersionIfNeeded
            os_signpost(.begin, log: log, name: "subscriptions", signpostID: .init(subscriptionID) ,"subscribe:%{public}s###source:%{public}s###id:%{public}d", name, source, subscriptionID)
        }

        public func end(state: SubscriptionEndState) {
            var completionCode: Int
            var errorMessage: String

            switch state {
            case .completed:
                completionCode = SubscriptionStateCode.completed.rawValue
                errorMessage = ""
            case .error(let message):
                completionCode = SubscriptionStateCode.error.rawValue
                errorMessage = message.appendingEllipsis(after: 50)
            case .cancelled:
                completionCode = SubscriptionStateCode.cancelled.rawValue
                errorMessage = ""
            }

            os_signpost(.end, log: log, name: "subscriptions", signpostID: .init(subscriptionID), "completion:%{public}d,error:###%{public}s###", completionCode, errorMessage)
        }

        public func event(value event: EventType, source: String = "") {
            _ = Self.emitVersionIfNeeded

            let text: String
            switch event {
            case .completion: text = ""
            case .value(let value): text = value
            case .error(let error): text = error
            case .cancelled: text = ""
            }

            os_signpost(.event, log: log, name: "subscriptions", signpostID: .init(subscriptionID), "subscription:%{public}s###type:%{public}s###value:%{public}s###source:%{public}s###id:%{public}d", name, event.type, text.appendingEllipsis(after: 50), source, subscriptionID)
        }

        static private var didEmitVersion = false

        static var emitVersionIfNeeded: Void = {
            os_signpost(.event, log: log, name: "subscriptions", signpostID: .exclusive, "version:%{public}d", Timelane.version)
        }()

        private enum SubscriptionStateCode: Int {
            case active = 0
            case cancelled = 1
            case error = 2
            case completed = 3
        }

        public enum SubscriptionEndState {
            case completed
            case error(String)
            case cancelled
        }

        public enum EventType {
            case value(String), completion, error(String), cancelled

            var type: String {
                switch self {
                case .completion: return "Completed"
                case .error: return "Error"
                case .value: return "Output"
                case .cancelled: return "Cancelled"
                }
            }
        }
    }
}

fileprivate extension String {
    func appendingEllipsis(after: Int) -> String {
        guard count > after else { return self }
        return prefix(after).appending("...")
    }
}
