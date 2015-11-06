//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Srdan Rasic (@srdanrasic)
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

public protocol OperationEventType {
  typealias Value
  typealias Error: ErrorType
  
  var _unbox: OperationEvent<Value, Error> { get }
}

public enum OperationEvent<Value, Error: ErrorType>: OperationEventType {
  
  case Next(Value)
  case Failure(Error)
  case Success
  
  public var _unbox: OperationEvent<Value, Error> {
    return self
  }
  
  public var isTerminal: Bool {
    switch self {
    case .Next: return false
    default: return true
    }
  }
  
  public func map<U>(transform: Value -> U) -> OperationEvent<U, Error> {
    switch self {
    case .Next(let event):
      return .Next(transform(event))
    case .Failure(let error):
      return .Failure(error)
    case .Success:
      return .Success
    }
  }
  
  public func mapError<F>(transform: Error -> F) -> OperationEvent<Value, F> {
    switch self {
    case .Next(let event):
      return .Next(event)
    case .Failure(let error):
      return .Failure(transform(error))
    case .Success:
      return .Success
    }
  }
  
  public func filter(include: Value -> Bool) -> Bool {
    switch self {
    case .Next(let value):
      if include(value) {
        return true
      } else {
        return false
      }
    default:
      return true
    }
  }
}

public func == <V: Equatable, E: ErrorType where E: Equatable>(left: OperationEvent<V, E>, right: OperationEvent<V, E>) -> Bool {
  switch (left, right) {
  case (.Next(let valueL), .Next(let valueR)):
    return valueL == valueR
  case (.Failure(let errorL), .Failure(let errorR)):
    return errorL == errorR
  case (.Success, .Success):
    return true
  default:
    return false
  }
}
