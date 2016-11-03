![](Assets/logo.png)

[![Platform](https://img.shields.io/cocoapods/p/ReactiveKit.svg?style=flat)](http://cocoadocs.org/docsets/ReactiveKit/3.0.0/)
[![Build Status](https://travis-ci.org/ReactiveKit/ReactiveKit.svg?branch=master)](https://travis-ci.org/ReactiveKit/ReactiveKit)
[![Join Us on Gitter](https://img.shields.io/badge/GITTER-join%20chat-blue.svg)](https://gitter.im/ReactiveKit/General)
[![Twitter](https://img.shields.io/badge/twitter-@srdanrasic-red.svg?style=flat)](https://twitter.com/srdanrasic)

__ReactiveKit__ is a Swift framework for reactive and functional reactive programming.

The framework is best used in a combination with the following extensions:

* [Bond](https://github.com/ReactiveKit/Bond) - UIKit and AppKit bindings, reactive delegates, data sources.
* [ReactiveAlamofire](https://github.com/ReactiveKit/ReactiveAlamofire) - Reactive extensions for Alamofire framework.

**Note: This README describes ReactiveKit v3. For changes check out the [migration section](#migration)!**

## Reactive Programming

Apps transform data. They take some data as input or generate data by themselves, transform that data into another data and output new data to the user. An app could take computer-friendly response from an API, transform it to a user-friendly text with a photo or video and render an article to the user. An app could take readings from the magnetometer, transform them into an orientation angle and render a nice needle to the user. There are many examples, but the pattern is obvious.

Basic premise of reactive programming is that the output should be derived from the input in such way that whenever the input changes, the output is changed too. Whenever new magnetometer readings are received, needle is updated. In addition to that, if the input is derived into the output using functional constructs like pure or higher-order functions one gets functional reactive programming.

ReactiveKit is a framework that provides mechanisms for leveraging functional reactive paradigm. It is based on ReactiveX API and provides *Signal* type that is generic both over the elements it generates and over the errors it can terminate with. ReactiveKit places great importance on errors and enforces you to handle them in compile time.

ReactiveKit aims to be the simplest yet complete framework for functional reactive programming in Swift. The goal is that you can dive in into each operator's implementation and understand it in under a minute. This makes ReactiveKit very lightweight and easy to learn, but also focused just on reactive paradigm. To get the best of the ReactiveKit in Cocoa / Cocoa Touch development use it with the Bond framework that provides reactive delegates, data sources and binding extensions for various UIKit and AppKit objects. Bond v5 is built on top of ReactiveKit. 

 
## Signals

Main type that ReactiveKit provides is `Signal`. It's used to represent a signal of events. Event can be anything from a button tap to a voice command or network response.

Signal event is defined by `Event` type and looks like this:

```swift
public enum Event<Element, Error: Swift.Error> {
  case next(Element)
  case failed(Error)
  case completed
}
```

Valid signals produce zero or more `.next` events and always terminate with either a `.completed` event or a `.failed` event in case of an error. Each `.next` event contains an associated element - the actual value or object produced by the signal.

### Creating Signals

There are many ways to create signals. Main one is by using the constructor that accepts a producer closure. The closure has one argument - an observer to which you send events. To send next element, use `next` method of the observer. When there are no more elements to be generated, send completion event using `completed` method. For example, to create a signal that produces first three positive integers do:

```swift
let counter = Signal<Int, NoError> { observer in

  // send first three positive integers
  observer.next(1)
  observer.next(2)
  observer.next(3)

  // complete
  observer.completed()

  return NonDisposable.instance
}
```

> Producer closure expects you to return a disposable. More about disposables can be found [here](#cancellation).

Notice how we defined signal as `Signal<Int, NoError>`. First generic argument specifies that the signal  emits elements of type `Int`. Second one specifies the error type that the signal can error-out with. `NoError` is a type without a constructor so it cannot be initialized. It is used to create signals that cannot error-out, so called _non-failable signals_. This is so common type so ReactiveKit provides a typealias `Signal1` defined as 

```swift
public typealias Signal1<Element> = Signal<Element, NoError>
```

That means that instead of `Signal<Int, NoError>` you can write just `Signal1<Int>`. 

> The type name `Signal1` might not be the happiest name, but we expect Swift 4 to introduce default generic arguments so we will be able to use just `Signal<Int>`.

When the producer fails to produce the element, you can signal an error. For example, mapping network request could looks like this:

```swift
let getUser = Signal<User, NetworkError> { observer in

  let task = api.getUser { result in
    switch result {
      case .success(let user):
        observer.next(user)
        observer.completed()
      case .failure(let error):
        observer.failed(error)
    }
  }
  
  task.start()

  return BlockDisposable {
    task.cancel()
  }
}
```

The example also shows to use a disposable. When the signal is disposed, the `BlockDisposable` will call its closure and cancel the task.


These were examples of how to manually create signals. There are few operators in the framework that you can use to create convenient signals. For example, when you need to convert a sequence to a signal, you will use following constructor:

```swift
let counter = Signal1.sequence([1, 2, 3])
```

To create a signal that produces an integer every second, do

```swift
let counter = Signal1<Int>.interval(1, queue: DispatchQueue.main)
```

> Note that this constructor requires a dispatch queue on which the events will be produced.

For more constructors, refer to the code reference.

### Observing Signals

Signal is only useful if it's being observed. To observe signal, use `observe` method:

```swift
counter.observe { event in
  print(event)
}
```

That will print following:

```
next(1)
next(2)
next(3)
completed
```

Most of the time we are interested only in the elements that the signal produces. Elements are associated with `.next` events and to observe just them you can do:

```swift
counter.observeNext { element in
  print(element)
}
```

That will print:

```
1
2
3
```

__Observing the signal actually starts the production of events.__ In other words, that producer closure we passed in the constructor is called only when you register an observer. If you register more that one observer, producer closure will be called once for each of them.

> Observers will be by default invoked on the thread (queue) on which the producer generates events. You can change that behaviour by passing another [execution context](#threading) using the `observeOn` method.

### Transforming Signals

Signals can be transformed into another signals. Methods that transform signals are often called _operators_. For example, to convert our signal of positive integers into a signal of positive even integers we can do

```swift
let evenCounter = counter.map { $0 * 2 }
```

or to convert it to a signal of integers divisible by three

```swift
let divisibleByThree = counter.filter { $0 % 3 == 0 }
```

or to convert each element to another signal that just triples that element and merge those new signals by concatenating them one after another 

```swift
let tripled = counter.flatMapConcat { number in
  return Signal1.sequence(Array(count: 3, repeatedValue: number))
}
``` 

and so on... There are many operators available. For more info on them, check out code reference.

### Handling Errors

One way to try to recover from an error is to just retry the signal again. To do so, just do

```swift
let betterFetch = fetchImage(url: ...).retry(3)
```

and smile thinking about how many number of lines would that take in the imperative paradigm.

Errors that cannot be handled with retry will happen eventually. Worst way to handle those is to just ignore and log any error that happens:

```swift
let image = fetchImage(url: ...).suppressError(logging: true)
```

Better way is to provide a default value in case of an error:

```swift
let image = fetchImage(url: ...).recover(with: Assets.placeholderImage)
```

Most powerful way is to `flatMapError` into another signal:

```swift
let image = fetchImage(url: ...).flatMapError { error in
  return Signal<UIImage> ...
}
```

There is no best way. Errors suck.

### Sharing Results

Whenever the observer is registered, the signal producer is executed all over again. To share results of a single execution, use `shareReplay` method.

```swift
let sharedCounter = counter.shareReplay()
```

### <a name="cancellation"></a> Cancellation

Observing the signal returns a disposable object. When the disposable object gets disposed, it will notify the producer to stop producing events and disable further event dispatches.

If you do

```swift
let disposable = aSignal.observeNext(...)
```

and later need to cancel the signal, just call `dispose`.

```swift
disposable.dispose()
```

From that point on the signal will not send any more events and the underlying task will be cancelled.

A general rule is to dispose all observations you make. It's recommended to keep a dispose bag where you should all of your disposables. The bag will automatically dispose all disposables you put in when it is deallocated.

```swift
class X {
  let disposeBag = DisposeBag()
  
  func y() {
    ...
    aSignal.observeNext { _ in
      ...
    }.disposeIn(disposeBag)
  }
}
```

> If you are using Bond framework and your class is a subclass or a descendent of NSObject, Bond provides the bag as an extension property `bnd_bag` that you can you out of the box.

### Hot Signals

If you need hot signals, i.e. signals that can generate events regardless of the observers, you can use `PublishSubject` type:

```swift
let numbers = PublishSubject<Int, NoError>()

numbers.observerNext { num in
  print(num)
}

numbers.next(1) // prints: 1
numbers.next(2) // prints: 2
...
```

### Property

Property wraps mutable state into an object that enables observation of that state. Whenever the state changes, an observer can be notified. Just like the `PublishSubject`, it represents a bridge into the imperative paradigm.

To create the property, just initialize it with the initial value.

```swift
let name = Property("Jim")
```

> `nil` is valid value for properties that wrap optional type.

Properties are signals just like signals of `Signal` type. They can be transformed into another signals, observed and bound in the same manner as signals can be.

For example, you can register an observer with `observe` or `observeNext` methods.

```swift
name.observeNext { value in
  print("Hi \(value)!")
}
```

> When you register an observer, it will be immediately invoked with the current value of the property so that snippet will print "Hi Jim!".

To change value of the property afterwards, just set the `value` property.

```swift
name.value = "Jim Kirk" // Prints: Hi Jim Kirk!
```

## <a name="threading"></a>Threading

ReactiveKit uses simple concept of execution contexts inspired by [BrightFutures](https://github.com/Thomvis/BrightFutures) to handle threading.

When you want to receive events on a specific dispatch queue, just use `context` extension of dispatch queue type `DispatchQueue`, for example: `DispatchQueue.main.context`, and pass it to the `observeOn` signal operator.

## Requirements

* iOS 8.0+ / macOS 10.9+ / tvOS 9.0+ / watchOS 2.0+
* Xcode 8

## Communication

* If you'd like to ask a general question, use Stack Overflow.
* If you'd like to ask a quick question or chat about the project, try [Gitter](https://gitter.im/ReactiveKit/General).
* If you found a bug, open an issue.
* If you have a feature request, open an issue.
* If you want to contribute, submit a pull request (include unit tests).
* You can track project plan and progress on [Waffle](https://waffle.io/ReactiveKit/ReactiveKit).

## Additional Documentation

* [ReactiveGitter](https://github.com/ReactiveKit/ReactiveGitter) - A ReactiveKit demo application.
* [ReactiveKit Reference](http://cocoadocs.org/docsets/ReactiveKit/3.0.0) - Code reference on Cocoadocs.
* [A Different Take on MVVM with Swift](http://rasic.info/a-different-take-on-mvvm-with-swift/) - App architecture example with ReactiveKit.
* [Implementing Reactive Delegates](http://rasic.info/implementing-reactive-delegates-in-swift-powered-by-objective-c/) - A post about reactive delegates implementation.

## Installation

> Bond is optional, but recommended for Cocoa / Cocoa touch development.

### CocoaPods

```
pod 'ReactiveKit', '~> 3.1'
pod 'Bond', '~> 5.0'
```

### Carthage

```
github "ReactiveKit/ReactiveKit" ~> 3.1
github "ReactiveKit/Bond" ~> 5.0
```

## <a name="migration"></a>Migration

### Migration from v2.x to v3.0

There are some big changes in v3. Major one is that ReactiveKit is joining forces with Bond to make great family of frameworks for functional reactive programming. Some things have been moved out of ReactiveKit to Bond in order to make ReactiveKit simpler and focused on FRP, while Bond has been reimplemented on top of ReactiveKit in order to provide great extensions like bindings, reactive delegates or observable collections.

What that means for you? Well, nothing has changed conceptually so your migration should come down to renaming. Stream and Operation had to be renamed because of conflicts with types from Foundation framework that's now lost NS prefix. A number of operators has been renamed to match Swift 3 syntax. CollectionProperty and reactive delegates are now part of Bond framework so make sure you import Bond in places where you use those. Binding extensions provided by ReactiveUIKit framework are now provided by Bond. Just import Bond instead of ReactiveUIKit  and change extension prefixes from `r` to `bnd`.

* Type `Operation` has been renamed to `Signal`.
* Type `Stream` is now implemented as a typealieas to non-failable `Signal` and named `Signal1`. Just replace all occurrences of Stream with Signal1 in your project.
* Operator `flatMap(_ strategy:)` has been replaced with `flatMapLatest`, `flatMapMerge` and `flatMapConcat` operators.
* Operator `toSignal` that returned stream of elements and stream of errors has been renamed to `branchOutError()`.
* Operator `toSignal(justLogError:)` has been renamed to `suppressError(logging:)`
* Operators like `takeLast`, `skipLast`, `feedNextInto`, `bindTo` have been renamed to `take(last:)`, `skip(last:)`, `feedNext(into:)`, `bind(to:)` etc.
* Each of the operators `combineLatest`, `zip`, `merge` and `amb` now has overloads for 6 arguments.
* `PushStream` and `PushOperation` have been replaced by `PublishSubject1` and `PublishSubject`.
* `Queue` has been removed. Use `DispatchQueue`.
* `CollectionProperty` has been moved to Bond framework and implemented as three types: `ObservableArray`, `ObservableDictionary` and `ObservableSet`.
* `ProtocolProxy` and other Foundation extensions have been moved to Bond framework. Prefix of extensions has been changed to `bnd`. For example `rBag` is renamed to `bnd_bag`.

## License

The MIT License (MIT)

Copyright (c) 2015-2016 Srdan Rasic (@srdanrasic)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
