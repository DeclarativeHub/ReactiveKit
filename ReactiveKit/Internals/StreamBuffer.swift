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

public class StreamBuffer<Event> {
  
  public var array: [Event] = []
  public let limit: Int
  
  public init(limit: Int = Int.max) {
    self.limit = limit
  }
  
  public func next(event: Event) {
    array.append(event)
    if array.count > limit {
      array = Array(array.suffixFrom(1))
    }
  }
  
  public func replay(observer: Event -> ()) {
    for value in array {
      observer(value)
    }
  }
  
  public func last() throws -> Event {
    if array.count > 0 {
      return array.last!
    } else {
      throw StreamBufferError.NoEvent
    }
  }
}

public enum StreamBufferError: ErrorType {
  case NoEvent
}
