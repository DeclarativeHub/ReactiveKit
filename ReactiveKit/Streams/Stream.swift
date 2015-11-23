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

public struct Stream<Event>: StreamType {
  
  public typealias Observer = Event -> ()
  
  public let producer: Observer -> DisposableType?
  
  public init(producer: Observer -> DisposableType?) {
    self.producer = producer
  }
  
  public func observe(on context: ExecutionContext? = ImmediateOnMainExecutionContext, observer: Observer) -> DisposableType {
    let serialDisposable = SerialDisposable(otherDisposable: nil)
    if let context = context {
      serialDisposable.otherDisposable = producer { event in
        if !serialDisposable.isDisposed {
          context {
            observer(event)
          }
        }
      }
    } else {
      serialDisposable.otherDisposable = producer { event in
        if !serialDisposable.isDisposed {
          observer(event)
        }
      }
    }
    return serialDisposable
  }
}

@warn_unused_result
public func create<Event>(producer producer: (Event -> ()) -> DisposableType?) -> Stream<Event> {
  return Stream<Event>(producer: producer)
}
