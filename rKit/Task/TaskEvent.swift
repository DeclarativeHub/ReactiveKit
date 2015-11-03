//
//  TaskEvent.swift
//  rTasks
//
//  Created by Srdan Rasic on 30/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

public protocol TaskEventType {
  typealias Value
  typealias Error: ErrorType
  
  var _unbox: TaskEvent<Value, Error> { get }
}

public enum TaskEvent<Value, Error: ErrorType>: TaskEventType {
  
  case Next(Value)
  case Failure(Error)
  case Success
  
  public var _unbox: TaskEvent<Value, Error> {
    return self
  }
  
  public var isTerminal: Bool {
    switch self {
    case .Next: return false
    default: return true
    }
  }
  
  public func map<U>(transform: Value -> U) -> TaskEvent<U, Error> {
    switch self {
    case .Next(let event):
      return .Next(transform(event))
    case .Failure(let error):
      return .Failure(error)
    case .Success:
      return .Success
    }
  }
  
  public func mapError<F>(transform: Error -> F) -> TaskEvent<Value, F> {
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
