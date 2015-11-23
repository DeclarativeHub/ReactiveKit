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

public extension StreamType where Event: OperationType {
  
  @warn_unused_result
  public func merge() -> Operation<Event.Value, Event.Error> {
    return create { observer in
      let compositeDisposable = CompositeDisposable()
      
      compositeDisposable += self.observe(on: nil) { task in
        compositeDisposable += task.observe(on: nil) { event in
          switch event {
          case .Next, .Failure:
            observer.observer(event)
          case .Success:
            break
          }
        }
      }
      return compositeDisposable
    }
  }
  
  @warn_unused_result
  public func switchToLatest() -> Operation<Event.Value, Event.Error>  {
    return create { observer in
      let serialDisposable = SerialDisposable(otherDisposable: nil)
      let compositeDisposable = CompositeDisposable([serialDisposable])
      
      compositeDisposable += self.observe(on: nil) { task in
        
        serialDisposable.otherDisposable?.dispose()
        serialDisposable.otherDisposable = task.observe(on: nil) { event in
          
          switch event {
          case .Failure(let error):
            observer.failure(error)
          case .Success:
            break
          case .Next(let value):
            observer.next(value)
          }
        }
      }
      
      return compositeDisposable
    }
  }
  
  @warn_unused_result
  public func concat() -> Operation<Event.Value, Event.Error>  {
    return create { observer in
      let serialDisposable = SerialDisposable(otherDisposable: nil)
      let compositeDisposable = CompositeDisposable([serialDisposable])
      
      var innerCompleted: Bool = true
      
      var taskQueue: [Event] = []
      
      var startNextOperation: (() -> ())! = nil
      startNextOperation = {
        innerCompleted = false
        let task = taskQueue.removeAtIndex(0)
        
        serialDisposable.otherDisposable?.dispose()
        serialDisposable.otherDisposable = task.observe(on: nil) { event in
          switch event {
          case .Failure(let error):
            observer.failure(error)
          case .Success:
            innerCompleted = true
            if taskQueue.count > 0 {
              startNextOperation()
            }
          case .Next(let value):
            observer.next(value)
          }
        }
      }
      
      let addToQueue = { (task: Event) -> () in
        taskQueue.append(task)
        if innerCompleted {
          startNextOperation()
        }
      }
      
      compositeDisposable += self.observe(on: nil) { task in
        addToQueue(task)
      }
      
      return compositeDisposable
    }
  }
}

public extension StreamType {
  
  @warn_unused_result
  public func flatMap<T: OperationType>(strategy: OperationFlatMapStrategy, transform: Event -> T) -> Operation<T.Value, T.Error> {
    switch strategy {
    case .Latest:
      return map(transform).switchToLatest()
    case .Merge:
      return map(transform).merge()
    case .Concat:
      return map(transform).concat()
    }
  }
}
