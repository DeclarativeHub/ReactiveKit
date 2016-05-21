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

public protocol ResultType {
  associatedtype Value
  associatedtype Error: ErrorType

  var value: Value? { get }
  var error: Error? { get }
}

/// An enum representing either a failure or a success.
public enum Result<T, E: ErrorType>: CustomStringConvertible {

  case Success(T)
  case Failure(E)

  /// Constructs a result with a success value.
  public init(value: T) {
    self = .Success(value)
  }

  /// Constructs a result with an error.
  public init(error: E) {
    self = .Failure(error)
  }

  public var description: String {
    switch self {
    case let .Success(value):
      return ".Success(\(value))"
    case let .Failure(error):
      return ".Failure(\(error))"
    }
  }
}

extension Result: ResultType {

  public var value: T? {
    if case .Success(let value) = self {
      return value
    } else {
      return nil
    }
  }

  public var error: E? {
    if case .Failure(let error) = self {
      return error
    } else {
      return nil
    }
  }

  public var unbox: Result<T, E> {
    return self
  }
}
