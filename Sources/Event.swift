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

/// An event of a sequence.
public enum Event<Element, Error: Swift.Error> {

  /// An event that carries next element.
  case next(Element)

  /// An event that represents failure. Carries an error.
  case failed(Error)

  /// An event that marks the completion of a sequence.
  case completed
}

extension Event {

  /// Return `true` in case of `.failure` or `.completed` event.
  public var isTerminal: Bool {
    switch self {
    case .next:
      return false
    default:
      return true
    }
  }

  /// Returns the next element, or nil if the event is not `.next`
  public var element: Element? {
    switch self {
    case .next(let element):
      return element

    default:
      return nil
    }
  }

  /// Return the failed error, or nil if the event is not `.failed`
  public var error: Error? {
    switch self {
    case .failed(let error):
      return error

    default:
      return nil
    }
  }
}
