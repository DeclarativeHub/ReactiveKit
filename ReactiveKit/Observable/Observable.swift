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

public protocol ObservableType: StreamType {
  typealias Value
  var value: Value { get set }
}

public class Observable<Value>: ActiveStream<Value>, ObservableType {
  
  public var value: Value {
    get {
      return try! lastEvent()
    }
    set {
      capturedObserver?(newValue)
    }
  }
    
  private var capturedObserver: (Value -> ())? = nil
  
  public init(_ value: Value) {
    var capturedObserver: (Value -> ())!
    super.init(limit: 1, producer: { observer in
      capturedObserver = observer
      observer(value)
      return nil
    })
    self.capturedObserver = capturedObserver
  }
  
  public init(@noescape producer: (Value -> ()) -> DisposableType?) {
    super.init(limit: 1, producer: { observer in
      return producer(observer)
    })
  }
}

@warn_unused_result
public func create<Value>(producer: (Value -> ()) -> DisposableType?) -> Observable<Value> {
  return Observable(producer: producer)
}

public extension Observable {
  
  @warn_unused_result
  public func map<U>(transform: Value -> U) -> Observable<U> {
    return create { observer in
      return self.observe(on: ImmediateExecutionContext) { event in
        observer(transform(event))
      }
    }
  }
  
  @warn_unused_result
  public func zipPrevious() -> Observable<(Value?, Value)> {
    return create { observer in
      var previous: Value? = nil
      return self.observe(on: ImmediateExecutionContext) { event in
        observer(previous, event)
        previous = event
      }
    }
  }
}

