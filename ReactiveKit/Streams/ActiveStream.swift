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

public class ActiveStream<Event>: StreamType {
  public typealias Observer = Event -> ()

  private typealias Token = Int64

  private var nextToken: Token = 0
  public var observers: ContiguousArray<Observer> = []
  private var observerStorage: [Token: Observer] = [:] {
    didSet {
      observers = ContiguousArray(observerStorage.values)
    }
  }
  
  private let lock = RecursiveLock(name: "com.ReactiveKit.ReactiveKit.ActiveStream")
  
  private var isDispatchInProgress: Bool = false
  private let deinitDisposable = CompositeDisposable()
  
  private weak var selfReference: Reference<ActiveStream<Event>>? = nil
  
  public init(@noescape producer: Observer -> DisposableType?) {
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
  
  public init() {
    let tmpSelfReference = Reference(self)
    tmpSelfReference.release()
    self.selfReference = tmpSelfReference
  }

  public func observe(on context: ExecutionContext? = ImmediateOnMainExecutionContext, observer: Observer) -> DisposableType {
    selfReference?.retain()

    var contextedObserver = observer
    if let context = context {
      contextedObserver = { e in context { observer(e) } }
    }

    let disposable = registerObserver(contextedObserver)

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
  
  public func next(event: Event) {
    guard !isDispatchInProgress else { return }
    
    lock.lock()
    isDispatchInProgress = true
    for observer in observers {
      observer(event)
    }
    isDispatchInProgress = false
    lock.unlock()
  }

  internal func registerDisposable(disposable: DisposableType) {
    deinitDisposable.addDisposable(disposable)
  }

  private func registerObserver(observer: Observer) -> DisposableType {
    lock.lock()
    let token = nextToken
    nextToken = nextToken + 1
    lock.unlock()

    observerStorage[token] = observer

    return BlockDisposable { [weak self] in
      self?.observerStorage.removeValueForKey(token)
    }
  }
  
  deinit {
    deinitDisposable.dispose()
  }
}

@warn_unused_result
public func create<Event>(producer: (Event -> ()) -> DisposableType?) -> ActiveStream<Event> {
  return ActiveStream<Event>(producer: producer)
}
