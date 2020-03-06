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

public enum TimelaneLaneType: Int, CaseIterable {
    case subscription, event
}

extension SignalProtocol {

    /// Logs the subscription and its events to the Timelane Instrument.
    ///
    ///  - Note: You can download the Timelane Instrument from http://timelane.tools
    ///
    ///  - Warning: When running on macOS 10.14, iOS 12, tvOS 12, watchOS 5 or later this operator
    ///  behaves as `lane` operator, but on earlier system versions the logging will be silently ignored.
    public func laneIfAvailable(_ name: String, filter: Set<TimelaneLaneType> = Set(TimelaneLaneType.allCases), file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> Signal<Element, Error> {
        if #available(macOS 10.14, iOS 12, tvOS 12, watchOS 5, *) {
            return lane(name, filter: filter, file: file, function: function, line: line)
        } else {
            return toSignal()
        }
    }

    /// The `lane` operator logs the subscription and its events to the Timelane Instrument.
    ///
    ///  - Note: You can download the Timelane Instrument from http://timelane.tools
    @available(macOS 10.14, iOS 12, tvOS 12, watchOS 5, *)
    public func lane(_ name: String, filter: Set<TimelaneLaneType> = Set(TimelaneLaneType.allCases), file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> Signal<Element, Error> {
        
        let fileName = file.description.components(separatedBy: "/").last!
        let source = "\(fileName):\(line) - \(function)"
        let subscription = Timelane.Subscription(name: name)

        return handleEvents(
            receiveSubscription: {
                if filter.contains(.subscription) {
                    subscription.begin(source: source)
                }
            },
            receiveOutput: { (value) in
                if filter.contains(.event) {
                    subscription.event(value: .value(String(describing: value)), source: source)
                }
            },
            receiveCompletion: { (completion) in
                if filter.contains(.subscription) {
                    switch completion {
                    case .finished:
                        subscription.end(state: .completed)
                    case .failure(let error):
                        subscription.end(state: .error(error.localizedDescription))
                    }
                }
                if filter.contains(.event) {
                    switch completion {
                    case .finished:
                        subscription.event(value: .completion, source: source)
                    case .failure(let error):
                        subscription.event(value: .error(error.localizedDescription), source: source)
                    }
                }
            },
            receiveCancel: {
                if filter.contains(.subscription) {
                    subscription.end(state: .cancelled)
                }
                if filter.contains(.event) {
                    subscription.event(value: .cancelled, source: source)
                }
            }
        )
    }
}
