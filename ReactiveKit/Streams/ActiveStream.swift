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

public protocol ActiveStreamType: StreamType {
  var buffer: StreamBuffer<Event> { get }
}

public class ActiveStream<Event>: ActiveStreamType {
  public typealias Sink = Event -> ()
  
  public var buffer: StreamBuffer<Event>
  
  private typealias Token = Int64
  
  private var observers = TokenizedCollection<Sink>()
  private let lock = RecursiveLock(name: "com.ReactiveKit.ReactiveKit.ActiveStream")
  
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
    observers.forEach { send in
      send(event)
    }
    isDispatchInProgress = false
    lock.unlock()
  }
  
  private func registerObserver(observer: Sink) -> DisposableType {
    return observers.insert(observer)
  }
  
  deinit {
    deinitDisposable.dispose()
  }
}

@warn_unused_result
public func create<Event>(limit: Int = Int.max, producer: (Event -> ()) -> DisposableType?) -> ActiveStream<Event> {
  return ActiveStream<Event>(limit: limit, producer: producer)
}


