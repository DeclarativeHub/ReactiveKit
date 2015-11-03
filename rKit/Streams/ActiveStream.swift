//
//  SharedProducer.swift
//  Streams
//
//  Created by Srdan Rasic on 18/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

public protocol ActiveStreamType: StreamType {
  var buffer: StreamBuffer<Event> { get }
}

public class ActiveStream<Event>: ActiveStreamType {
  public typealias Sink = Event -> ()
  
  public var buffer: StreamBuffer<Event>
  
  private typealias Token = Int64
  
  private var observers: [Token:Sink] = [:]
  private var nextToken: Token = 0
  private let lock = RecursiveLock(name: "com.swift-bond.Bond.EventProducer")
  
  private var isDispatchInProgress: Bool = false
  private let deinitDisposable = CompositeDisposable()
  
  private weak var selfReference: Reference<ActiveStream<Event>>? = nil
  
  public required init(limit: Int = 0, @noescape producer: Sink -> DisposableType?) {
    self.buffer = StreamBuffer(limit: limit)
    
    let tmpSelfReference = Reference(self)
    tmpSelfReference.release()
    
    let disposable = producer { event in
      tmpSelfReference.object?.next(event)
    }
    
    if let disposable = disposable {
      deinitDisposable.addDisposable(disposable)
    }
    
    self.selfReference = tmpSelfReference
  }
  
  public func observe(sink: Sink) -> DisposableType {
    return observe(on: ImmediateExecutionContext, sink: sink)
  }
  
  public func observe(on context: ExecutionContext, sink: Sink) -> DisposableType {
    selfReference?.retain()
    
    let observer = { e in context { sink(e) } }
    
    let disposable = registerObserver(observer)
    buffer.replay(observer)
    
    let cleanupDisposable = BlockDisposable { [weak self] in
      disposable.dispose()
      
      if let unwrappedSelf = self {
        if unwrappedSelf.observers.count == 0 {
          unwrappedSelf.selfReference?.release()
        }
      }
    }
    
    deinitDisposable.addDisposable(cleanupDisposable)
    return cleanupDisposable
  }
  
  
  public func lastEvent() throws -> Event {
    return try buffer.last()
  }
  
  internal func next(event: Event) {
    buffer.next(event)
    dispatchNext(event)
  }
  
  internal func registerDisposable(disposable: DisposableType) {
    deinitDisposable.addDisposable(disposable)
  }
  
  private func dispatchNext(event: Event) {
    guard !isDispatchInProgress else { return }
    
    lock.lock()
    isDispatchInProgress = true
    for (_, send) in observers {
      send(event)
    }
    isDispatchInProgress = false
    lock.unlock()
  }
  
  private func registerObserver(observer: Sink) -> DisposableType {
    lock.lock()
    let token = nextToken
    nextToken = nextToken + 1
    lock.unlock()
    
    observers[token] = observer
    
    return BlockDisposable { [weak self] in
      self?.observers.removeValueForKey(token)
    }
  }
  
  deinit {
    deinitDisposable.dispose()
  }
}

@warn_unused_result
public func create<Event>(limit: Int = Int.max, producer: (Event -> ()) -> DisposableType?) -> ActiveStream<Event> {
  return ActiveStream<Event>(limit: limit, producer: producer)
}


