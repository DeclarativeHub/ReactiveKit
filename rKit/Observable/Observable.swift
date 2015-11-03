//
//  ObservableValue.swift
//  rCollections
//
//  Created by Srdan Rasic on 30/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

infix operator <~ { associativity left precedence 160 }

public protocol ObservableType: StreamType {}

public class Observable<Value>: ActiveStream<Value>, ObservableType {
  
  public var value: Value {
    get {
      return try! lastEvent()
    }
    set {
      dispatch(newValue)
    }
  }
    
  private var capturedSink: (Value -> ())? = nil
  
  public init(_ value: Value) {
    var capturedSink: (Value -> ())!
    super.init(limit: 1, producer: { sink in
      capturedSink = sink
      sink(value)
      return nil
    })
    self.capturedSink = capturedSink
  }
  
  public init(@noescape producer: (Value -> ()) -> DisposableType?) {
    super.init(limit: 1, producer: { sink in
      return producer(sink)
    })
  }
  
  public func dispatch(value: Value) {
    capturedSink?(value)
  }
}

@warn_unused_result
public func create<Value>(producer: (Value -> ()) -> DisposableType?) -> Observable<Value> {
  return Observable(producer: producer)
}

public extension Observable {
  
  @warn_unused_result
  public func map<U>(transform: Value -> U) -> Observable<U> {
    return create { sink in
      return self.observe(on: ImmediateExecutionContext) { event in
        sink(transform(event))
      }
    }
  }
  
  @warn_unused_result
  public func zipPrevious() -> Observable<(Value?, Value)> {
    return create { sink in
      var previous: Value? = nil
      return self.observe(on: ImmediateExecutionContext) { event in
        sink(previous, event)
        previous = event
      }
    }
  }
}

public func <~ <T>(left: Observable<T>, right: T) {
  return left.value = right
}

