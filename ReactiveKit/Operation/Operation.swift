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

public protocol OperationType: StreamType {
  typealias Value
  typealias Error: ErrorType

  func lift<U, F: ErrorType>(transform: Stream<OperationEvent<Value, Error>> -> Stream<OperationEvent<U, F>>) -> Operation<U, F>
  func observe(on context: ExecutionContext?, observer: OperationEvent<Value, Error> -> ()) -> DisposableType
}

public struct Operation<Value, Error: ErrorType>: OperationType {
  
  private let stream: Stream<OperationEvent<Value, Error>>
  
  public init(producer: (OperationObserver<Value, Error> -> DisposableType?)) {
    stream = Stream  { observer in
      var completed: Bool = false
      
      return producer(OperationObserver { event in
        if !completed {
          observer(event)
          completed = event._unbox.isTerminal
        }
      })
    }
  }
  
  public func observe(on context: ExecutionContext? = ImmediateOnMainExecutionContext, observer: OperationEvent<Value, Error> -> ()) -> DisposableType {
    return stream.observe(on: context, observer: observer)
  }
  
  public static func succeeded(with value: Value) -> Operation<Value, Error> {
    return create { observer in
      observer.next(value)
      observer.success()
      return nil
    }
  }
  
  public static func failed(with error: Error) -> Operation<Value, Error> {
    return create { observer in
      observer.failure(error)
      return nil
    }
  }
  
  public func lift<U, F: ErrorType>(transform: Stream<OperationEvent<Value, Error>> -> Stream<OperationEvent<U, F>>) -> Operation<U, F> {
    return create { observer in
      return transform(self.stream).observe(on: nil, observer: observer.observer)
    }
  }
}


public func create<Value, Error: ErrorType>(producer producer: OperationObserver<Value, Error> -> DisposableType?) -> Operation<Value, Error> {
  return Operation<Value, Error> { observer in
    return producer(observer)
  }
}

public extension OperationType {
  
  public func on(next next: (Value -> ())? = nil, success: (() -> ())? = nil, failure: (Error -> ())? = nil, start: (() -> Void)? = nil, completed: (() -> Void)? = nil, context: ExecutionContext? = ImmediateOnMainExecutionContext) -> Operation<Value, Error> {
    return create { observer in
      start?()
      return self.observe(on: context) { event in
        switch event {
        case .Next(let value):
          next?(value)
        case .Failure(let error):
          failure?(error)
          completed?()
        case .Success:
          success?()
          completed?()
        }
        
        observer.observer(event)
      }
    }
  }
  
  public func observeNext(on context: ExecutionContext? = ImmediateOnMainExecutionContext, observer: Value -> ()) -> DisposableType {
    return self.observe(on: context) { event in
      switch event {
      case .Next(let event):
        observer(event)
      default: break
      }
    }
  }
  
  public func observeError(on context: ExecutionContext? = ImmediateOnMainExecutionContext, observer: Error -> ()) -> DisposableType {
    return self.observe(on: context) { event in
      switch event {
      case .Failure(let error):
        observer(error)
      default: break
      }
    }
  }
  
  @warn_unused_result
  public func shareNext(limit: Int = Int.max, context: ExecutionContext? = nil) -> ObservableBuffer<Value> {
    return ObservableBuffer(limit: limit) { observer in
      return self.observeNext(on: context, observer: observer)
    }
  }

  @warn_unused_result
  public func map<U>(transform: Value -> U) -> Operation<U, Error> {
    return lift { $0.map { $0.map(transform) } }
  }
  
  @warn_unused_result
  public func tryMap<U>(transform: Value -> Result<U, Error>) -> Operation<U, Error> {
    return lift { $0.map { operationEvent in
        switch operationEvent {
        case .Next(let value):
          switch transform(value) {
          case let .Success(value):
            return .Next(value)
          case let .Failure(error):
            return .Failure(error)
          }
        case .Failure(let error):
          return .Failure(error)
        case .Success:
          return .Success
        }
      }
    }
  }
  
  @warn_unused_result
  public func mapError<F>(transform: Error -> F) -> Operation<Value, F> {
    return lift { $0.map { $0.mapError(transform) } }
  }
  
  @warn_unused_result
  public func filter(include: Value -> Bool) -> Operation<Value, Error> {
    return lift { $0.filter { $0.filter(include) } }
  }
  
  @warn_unused_result
  public func switchTo(context: ExecutionContext) -> Operation<Value, Error> {
    return lift { $0.switchTo(context) }
  }
  
  @warn_unused_result
  public func throttle(seconds: Double, on queue: Queue) -> Operation<Value, Error> {
    return lift { $0.throttle(seconds, on: queue) }
  }
  
  @warn_unused_result
  public func skip(count: Int) -> Operation<Value, Error> {
    return lift { $0.skip(count) }
  }

  @warn_unused_result
  public func startWith(event: Value) -> Operation<Value, Error> {
    return lift { $0.startWith(.Next(event)) }
  }
  
  @warn_unused_result
  public func retry(var count: Int) -> Operation<Value, Error> {
    return create { observer in
      let serialDisposable = SerialDisposable(otherDisposable: nil)
      
      var attempt: (() -> Void)?

      attempt = {
        serialDisposable.otherDisposable?.dispose()
        serialDisposable.otherDisposable = self.observe(on: nil) { event in
          switch event {
          case .Failure(let error):
            if count > 0 {
              count--
              attempt?()
            } else {
              observer.failure(error)
              attempt = nil
            }
          default:
            observer.observer(event._unbox)
            attempt = nil
          }
        }
      }
      
      attempt?()
      return BlockDisposable {
        serialDisposable.dispose()
        attempt = nil
      }
    }
  }

  @warn_unused_result
  public func take(count: Int) -> Operation<Value, Error> {
    return create { observer in

      if count <= 0 {
        observer.success()
        return nil
      }

      var taken = 0

      let serialDisposable = SerialDisposable(otherDisposable: nil)
      serialDisposable.otherDisposable = self.observe(on: nil) { event in

        switch event {
        case .Next(let value):
          if taken < count {
            taken += 1
            observer.next(value)
          }
          if taken == count {
            observer.success()
            serialDisposable.otherDisposable?.dispose()
          }
        default:
          observer.observer(event)
        }
      }

      return serialDisposable
    }
  }

  @warn_unused_result
  public func first() -> Operation<Value, Error> {
    return take(1)
  }

  @warn_unused_result
  public func takeLast(count: Int = 1) -> Operation<Value, Error> {
    return create { observer in

      var values: [Value] = []
      values.reserveCapacity(count)

      return self.observe(on: nil) { event in

        switch event {
        case .Next(let value):
          while values.count + 1 > count {
            values.removeFirst()
          }
          values.append(value)
        case .Success:
          values.forEach(observer.next)
          observer.success()
        default:
          observer.observer(event)
        }
      }
    }
  }

  @warn_unused_result
  public func last() -> Operation<Value, Error> {
    return takeLast(1)
  }

  @warn_unused_result
  public func pausable<S: StreamType where S.Event == Bool>(by: S) -> Operation<Value, Error> {
    return create { observer in

      var allowed: Bool = true

      let compositeDisposable = CompositeDisposable()
      compositeDisposable += by.observe(on: nil) { value in
        allowed = value
      }

      compositeDisposable += self.observe(on: nil) { event in
        switch event {
        case .Next(let value):
          if allowed {
            observer.next(value)
          }
        default:
          observer.observer(event)
        }
      }

      return compositeDisposable
    }
  }

  @warn_unused_result
  public func scan<U>(initial: U, _ combine: (U, Value) -> U) -> Operation<U, Error> {
    return create { observer in

      var scanned = initial

      return self.observe(on: nil) { event in
        observer.observer(event.map { value in
          scanned = combine(scanned, value)
          return scanned
        })
      }
    }
  }

  @warn_unused_result
  public func reduce<U>(initial: U, _ combine: (U, Value) -> U) -> Operation<U, Error> {
    return Operation<U, Error> { observer in
      observer.next(initial)
      return self.scan(initial, combine).observe(on: nil, observer: observer.observer)
    }.takeLast()
  }

  @warn_unused_result
  public func collect() -> Operation<[Value], Error> {
    return reduce([], { memo, new in memo + [new] })
  }

  @warn_unused_result
  public func combineLatestWith<S: OperationType where S.Error == Error>(other: S) -> Operation<(Value, S.Value), Error> {
    return create { observer in
      let queue = Queue(name: "com.ReactiveKit.ReactiveKit.Operation.CombineLatestWith")
      
      var latestSelfValue: Value! = nil
      var latestOtherValue: S.Value! = nil
      
      var latestSelfEvent: OperationEvent<Value, Error>! = nil
      var latestOtherEvent: OperationEvent<S.Value, S.Error>! = nil
      
      let dispatchNextIfPossible = { () -> () in
        if let latestSelfValue = latestSelfValue, latestOtherValue = latestOtherValue {
          observer.next(latestSelfValue, latestOtherValue)
        }
      }
      
      let onBoth = { () -> () in
        if let latestSelfEvent = latestSelfEvent, let latestOtherEvent = latestOtherEvent {
          switch (latestSelfEvent, latestOtherEvent) {
          case (.Success, .Success):
            observer.success()
          case (.Next(let selfValue), .Next(let otherValue)):
            latestSelfValue = selfValue
            latestOtherValue = otherValue
            dispatchNextIfPossible()
          case (.Next(let selfValue), .Success):
            latestSelfValue = selfValue
            dispatchNextIfPossible()
          case (.Success, .Next(let otherValue)):
            latestOtherValue = otherValue
            dispatchNextIfPossible()
          default:
            dispatchNextIfPossible()
          }
        }
      }
      
      let selfDisposable = self.observe(on: nil) { event in
        if case .Failure(let error) = event {
          observer.failure(error)
        } else {
          queue.sync {
            latestSelfEvent = event
            onBoth()
          }
        }
      }
      
      let otherDisposable = other.observe(on: nil) { event in
        if case .Failure(let error) = event {
          observer.failure(error)
        } else {
          queue.sync {
            latestOtherEvent = event
            onBoth()
          }
        }
      }
      
      return CompositeDisposable([selfDisposable, otherDisposable])
    }
  }

  @warn_unused_result
  public func zipWith<S: OperationType where S.Error == Error>(other: S) -> Operation<(Value, S.Value), Error> {
    return create { observer in
      let queue = Queue(name: "com.ReactiveKit.ReactiveKit.ZipWith")
      
      var selfBuffer = Array<Value>()
      var selfCompleted = false
      var otherBuffer = Array<S.Value>()
      var otherCompleted = false
      
      let dispatchIfPossible = {
        while selfBuffer.count > 0 && otherBuffer.count > 0 {
          observer.next((selfBuffer[0], otherBuffer[0]))
          selfBuffer.removeAtIndex(0)
          otherBuffer.removeAtIndex(0)
        }
        
        if (selfCompleted && selfBuffer.isEmpty) || (otherCompleted && otherBuffer.isEmpty) {
          observer.success()
        }
      }
      
      let selfDisposable = self.observe(on: nil) { event in
        switch event {
        case .Failure(let error):
          observer.failure(error)
        case .Success:
          queue.sync {
            selfCompleted = true
            dispatchIfPossible()
          }
        case .Next(let value):
          queue.sync {
            selfBuffer.append(value)
            dispatchIfPossible()
          }
        }
      }
      
      let otherDisposable = other.observe(on: nil) { event in
        switch event {
        case .Failure(let error):
          observer.failure(error)
        case .Success:
          queue.sync {
            otherCompleted = true
            dispatchIfPossible()
          }
        case .Next(let value):
          queue.sync {
            otherBuffer.append(value)
            dispatchIfPossible()
          }
        }
      }
      
      return CompositeDisposable([selfDisposable, otherDisposable])
    }
  }
}

public extension OperationType where Value: OptionalType {
  
  @warn_unused_result
  public func ignoreNil() -> Operation<Value.Wrapped?, Error> {
    return lift { $0.filter { $0.filter { $0._unbox != nil } }.map { $0.map { $0._unbox! } } }
  }
}

public extension OperationType where Value: OperationType, Value.Error == Error {
  
  @warn_unused_result
  public func merge() -> Operation<Value.Value, Value.Error> {
    return create { observer in
      let queue = Queue(name: "com.ReactiveKit.ReactiveKit.Operation.Merge")
      
      var numberOfOperations = 1
      let compositeDisposable = CompositeDisposable()
      
      let decrementNumberOfOperations = { () -> () in
        queue.sync {
          numberOfOperations -= 1
          if numberOfOperations == 0 {
            observer.success()
          }
        }
      }
      
      compositeDisposable += self.observe(on: nil) { taskEvent in
        
        switch taskEvent {
        case .Failure(let error):
          return observer.failure(error)
        case .Success:
          decrementNumberOfOperations()
        case .Next(let task):
          queue.sync {
            numberOfOperations += 1
          }
          compositeDisposable += task.observe(on: nil) { event in
            switch event {
            case .Next, .Failure:
              observer.observer(event)
            case .Success:
              decrementNumberOfOperations()
            }
          }
        }
      }
      return compositeDisposable
    }
  }
  
  @warn_unused_result
  public func switchToLatest() -> Operation<Value.Value, Value.Error>  {
    return create { observer in
      let serialDisposable = SerialDisposable(otherDisposable: nil)
      let compositeDisposable = CompositeDisposable([serialDisposable])
      
      var outerCompleted: Bool = false
      var innerCompleted: Bool = false
      
      compositeDisposable += self.observe(on: nil) { taskEvent in
        
        switch taskEvent {
        case .Failure(let error):
          observer.failure(error)
        case .Success:
          outerCompleted = true
          if innerCompleted {
            observer.success()
          }
        case .Next(let innerOperation):
          innerCompleted = false
          serialDisposable.otherDisposable?.dispose()
          serialDisposable.otherDisposable = innerOperation.observe(on: nil) { event in
            
            switch event {
            case .Failure(let error):
              observer.failure(error)
            case .Success:
              innerCompleted = true
              if outerCompleted {
                observer.success()
              }
            case .Next(let value):
              observer.next(value)
            }
          }
        }
      }
      
      return compositeDisposable
    }
  }
  
  @warn_unused_result
  public func concat() -> Operation<Value.Value, Value.Error>  {
    return create { observer in
      let queue = Queue(name: "com.ReactiveKit.ReactiveKit.Operation.Concat")
      
      let serialDisposable = SerialDisposable(otherDisposable: nil)
      let compositeDisposable = CompositeDisposable([serialDisposable])
      
      var outerCompleted: Bool = false
      var innerCompleted: Bool = true
      
      var taskQueue: [Value] = []
      
      var startNextOperation: (() -> ())! = nil
      startNextOperation = {
        innerCompleted = false

        let task: Value = queue.sync {
          return taskQueue.removeAtIndex(0)
        }
        
        serialDisposable.otherDisposable?.dispose()
        serialDisposable.otherDisposable = task.observe(on: nil) { event in
          switch event {
          case .Failure(let error):
            observer.failure(error)
          case .Success:
            innerCompleted = true
            if taskQueue.count > 0 {
              startNextOperation()
            } else if outerCompleted {
              observer.success()
            }
          case .Next(let value):
            observer.next(value)
          }
        }
      }
      
      let addToQueue = { (task: Value) -> () in
        queue.sync {
          taskQueue.append(task)
        }
        
        if innerCompleted {
          startNextOperation()
        }
      }

      compositeDisposable += self.observe(on: nil) { taskEvent in
        
        switch taskEvent {
        case .Failure(let error):
          observer.failure(error)
        case .Success:
          outerCompleted = true
          if innerCompleted {
            observer.success()
          }
        case .Next(let innerOperation):
          addToQueue(innerOperation)
        }
      }
      
      return compositeDisposable
    }
  }
}

public enum OperationFlatMapStrategy {
  case Latest
  case Merge
  case Concat
}

public extension OperationType {
  
  @warn_unused_result
  public func flatMap<T: OperationType where T.Error == Error>(strategy: OperationFlatMapStrategy, transform: Value -> T) -> Operation<T.Value, T.Error> {
    switch strategy {
    case .Latest:
      return map(transform).switchToLatest()
    case .Merge:
      return map(transform).merge()
    case .Concat:
      return map(transform).concat()
    }
  }
  
  @warn_unused_result
  public func flatMapError<T: OperationType where T.Value == Value>(recover: Error -> T) -> Operation<T.Value, T.Error> {
    return create { observer in
      let serialDisposable = SerialDisposable(otherDisposable: nil)
      
      serialDisposable.otherDisposable = self.observe(on: nil) { taskEvent in
        switch taskEvent {
        case .Next(let value):
          observer.next(value)
        case .Success:
          observer.success()
        case .Failure(let error):
          serialDisposable.otherDisposable = recover(error).observe(on: nil) { event in
            observer.observer(event)
          }
        }
      }
      
      return serialDisposable
    }
  }
}

@warn_unused_result
public func combineLatest<A: OperationType, B: OperationType where A.Error == B.Error>(a: A, _ b: B) -> Operation<(A.Value, B.Value), A.Error> {
  return a.combineLatestWith(b)
}

@warn_unused_result
public func zip<A: OperationType, B: OperationType where A.Error == B.Error>(a: A, _ b: B) -> Operation<(A.Value, B.Value), A.Error> {
  return a.zipWith(b)
}

@warn_unused_result
public func combineLatest<A: OperationType, B: OperationType, C: OperationType where A.Error == B.Error, A.Error == C.Error>(a: A, _ b: B, _ c: C) -> Operation<(A.Value, B.Value, C.Value), A.Error> {
  return combineLatest(a, b).combineLatestWith(c).map { ($0.0, $0.1, $1) }
}

@warn_unused_result
public func zip<A: OperationType, B: OperationType, C: OperationType where A.Error == B.Error, A.Error == C.Error>(a: A, _ b: B, _ c: C) -> Operation<(A.Value, B.Value, C.Value), A.Error> {
  return zip(a, b).zipWith(c).map { ($0.0, $0.1, $1) }
}

@warn_unused_result
public func combineLatest<A: OperationType, B: OperationType, C: OperationType, D: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error>(a: A, _ b: B, _ c: C, _ d: D) -> Operation<(A.Value, B.Value, C.Value, D.Value), A.Error> {
  return combineLatest(a, b, c).combineLatestWith(d).map { ($0.0, $0.1, $0.2, $1) }
}

@warn_unused_result
public func zip<A: OperationType, B: OperationType, C: OperationType, D: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error>(a: A, _ b: B, _ c: C, _ d: D) -> Operation<(A.Value, B.Value, C.Value, D.Value), A.Error> {
  return zip(a, b, c).zipWith(d).map { ($0.0, $0.1, $0.2, $1) }
}

@warn_unused_result
public func combineLatest<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error>
  (a: A, _ b: B, _ c: C, _ d: D, _ e: E) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value), A.Error>
{
  return combineLatest(a, b, c, d).combineLatestWith(e).map { ($0.0, $0.1, $0.2, $0.3, $1) }
}

@warn_unused_result
public func zip<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error>
  (a: A, _ b: B, _ c: C, _ d: D, _ e: E) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value), A.Error>
{
  return zip(a, b, c, d).zipWith(e).map { ($0.0, $0.1, $0.2, $0.3, $1) }
}

@warn_unused_result
public func combineLatest<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error>
  ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value), A.Error>
{
  return combineLatest(a, b, c, d, e).combineLatestWith(f).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $1) }
}

@warn_unused_result
public func zip<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error>
  ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value), A.Error>
{
  return zip(a, b, c, d, e).zipWith(f).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $1) }
}

@warn_unused_result
public func combineLatest<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error>
  ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value), A.Error>
{
  return combineLatest(a, b, c, d, e, f).combineLatestWith(g).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $1) }
}

@warn_unused_result
public func zip<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error>
  ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value), A.Error>
{
  return zip(a, b, c, d, e, f).zipWith(g).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $1) }
}

@warn_unused_result
public func combineLatest<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType, H: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error, A.Error == H.Error>
  ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value), A.Error>
{
  return combineLatest(a, b, c, d, e, f, g).combineLatestWith(h).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $1) }
}

@warn_unused_result
public func zip<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType, H: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error, A.Error == H.Error>
  ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value), A.Error>
{
  return zip(a, b, c, d, e, f, g).zipWith(h).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $1) }
}

@warn_unused_result
public func combineLatest<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType, H: OperationType, I: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error, A.Error == H.Error, A.Error == I.Error>
  ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H, _ i: I) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value, I.Value), A.Error>
{
  return combineLatest(a, b, c, d, e, f, g, h).combineLatestWith(i).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7, $1) }
}

@warn_unused_result
public func zip<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType, H: OperationType, I: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error, A.Error == H.Error, A.Error == I.Error>
  ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H, _ i: I) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value, I.Value), A.Error>
{
  return zip(a, b, c, d, e, f, g, h).zipWith(i).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7, $1) }
}

@warn_unused_result
public func combineLatest<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType, H: OperationType, I: OperationType, J: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error, A.Error == H.Error, A.Error == I.Error, A.Error == J.Error>
  ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H, _ i: I, _ j: J) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value, I.Value, J.Value), A.Error>
{
  return combineLatest(a, b, c, d, e, f, g, h, i).combineLatestWith(j).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7, $0.8, $1) }
}

@warn_unused_result
public func zip<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType, H: OperationType, I: OperationType, J: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error, A.Error == H.Error, A.Error == I.Error, A.Error == J.Error>
  ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H, _ i: I, _ j: J) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value, I.Value, J.Value), A.Error>
{
  return zip(a, b, c, d, e, f, g, h, i).zipWith(j).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7, $0.8, $1) }
}

@warn_unused_result
public func combineLatest<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType, H: OperationType, I: OperationType, J: OperationType, K: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error, A.Error == H.Error, A.Error == I.Error, A.Error == J.Error, A.Error == K.Error>
  ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H, _ i: I, _ j: J, _ k: K) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value, I.Value, J.Value, K.Value), A.Error>
{
  return combineLatest(a, b, c, d, e, f, g, h, i, j).combineLatestWith(k).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7, $0.8, $0.9, $1) }
}

@warn_unused_result
public func zip<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType, H: OperationType, I: OperationType, J: OperationType, K: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error, A.Error == H.Error, A.Error == I.Error, A.Error == J.Error, A.Error == K.Error>
  ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H, _ i: I, _ j: J, _ k: K) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value, I.Value, J.Value, K.Value), A.Error>
{
  return zip(a, b, c, d, e, f, g, h, i, j).zipWith(k).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7, $0.8, $0.9, $1) }
}
