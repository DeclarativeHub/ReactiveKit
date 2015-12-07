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

public final class Observable<Value>: ActiveStream<Value>, ObservableType {
  public typealias WillSetBlockType = (value: Value, newValue: Value) -> ()
  private var willSetBlock : WillSetBlockType?
  public typealias DidSetBlockType = (oldValue: Value, value: Value) -> ()
  private var didSetBlock : DidSetBlockType?
  
  public var value: Value {
    willSet {
      willSetBlock?(value: value, newValue:newValue)
    }
    didSet {
      didSetBlock?(oldValue: oldValue, value:value)
      super.next(value)
    }
  }

  public init(_ value: Value) {
    self.value = value
    super.init()
  }

  public override func next(event: Value) {
    self.value = event
  }

  public override func observe(on context: ExecutionContext? = ImmediateOnMainExecutionContext, observer: Observer) -> DisposableType {
    let disposable = super.observe(on: context, observer: observer)
    observer(value)
    return disposable
  }

  public func willSet(willSetBlock: WillSetBlockType?) -> Observable<Value> {
    self.willSetBlock = willSetBlock
    return self
  }

  public func didSet(didSetBlock: DidSetBlockType?) -> Observable<Value> {
    self.didSetBlock = didSetBlock
    return self
  }

}
