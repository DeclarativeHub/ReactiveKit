![](Assets/logo.png)

[![Platform](https://img.shields.io/cocoapods/p/ReactiveKit.svg?style=flat)](http://cocoadocs.org/docsets/ReactiveKit/)
[![Build Status](https://travis-ci.org/ReactiveKit/ReactiveKit.svg?branch=master)](https://travis-ci.org/ReactiveKit/ReactiveKit)
[![Join Us on Gitter](https://img.shields.io/badge/GITTER-join%20chat-blue.svg)](https://gitter.im/ReactiveKit/General)
[![Twitter](https://img.shields.io/badge/twitter-@srdanrasic-red.svg?style=flat)](https://twitter.com/srdanrasic)

__ReactiveKit__ is a lightweight Swift framework for reactive and functional reactive programming. With just over 2000 lines of code it enables you to get into reactive world today.

The framework is best used in a combination with [Bond](https://github.com/ReactiveKit/Bond) that provides UIKit and AppKit bindings, reactive delegates and data sources.

This document will introduce the framework by going through its implementation. By the end you should be equipped with a pretty good understanding of how is the framework implemented and what are the best ways to use it.

## Summary

* [Introduction](#introduction)
* [Signals](#signals)
* [Wrapping asynchronous calls into signals](#wrapping-asynchronous-calls-into-signals)
* [Disposing signals](#disposing-signals)
* [Transforming signals](#transforming-signals)
* [More about errors](#more-about-errors)
* [Creating simple signals](#creating-simple-signals)
* [Disposing in a bag](#disposing-in-a-bag)
* [Threading](#threading)
* [Bindings](#bindings)
  * [Binding targets](#binding-targets)
  * [Binding to a property](#binding-to-a-property)
* [Sharing sequences of events](#sharing-sequences-of-events)
* [Subjects](#subjects)
* [Connectable signals](#connectable-signals)
  * [Implementing shareReplay operator](#implementing-sharereplay-operator)
* [Handling signal errors](#handling-signal-errors)
  * [Generalized error handling](#generalized-error-handling)
* [Tracking signal state](#tracking-signal-state)
  * [Single signal state tracking](#single-signal-state-tracking)
* [Property](#property)
* [Other common patterns](#other-common-patterns)
  * [Performing an action on .next event](#performing-an-action-on-next-event)
  * [Combining multiple signals](#combining-multiple-signals)
* [Requirements](#requirements)
* [Installation](#installation)
  * [CocoaPods](#cocoapods)
  * [Carthage](#carthage)
* [Communication](#communication)
* [Additional Documentation](#additional-documentation)
* [License](#license)

## Introduction

Consider how text of a text field changes as user enters his name. Each entered letter gives us a new state.

```
---[J]---[Ji]---[Jim]--->
```

We can think of these state changes as a sequence of events. It is quite similar to an array or a lists, but with the difference that events are generated over time as opposed to having them all in memory at once.

The idea behind reactive programming is that everything can be represented as a sequence. Let us consider another example - a network request.

```
---[Response]--->
```

Outcome of a network request is a response. Although we have only one response, we can still think of it as a sequence. An array of one element is still an array.

Arrays are finite so they have a property that we call size. It is a measure of how much memory the array occupies. When we talk about sequences over time, we do not know how many events will they generate during their lifetime. We do not know how many letters will the user enter. However, we would still like to know when the sequence is done generating the events.

To get that information, we can introduce a special kind of event - a completion event. It is an event that marks the end of a sequence. No event shall follow the completion event.

We will denote completion event visually with a vertical bar.

```
---[J]---[Ji]---[Jim]---|--->
```

Completion event is important because it tells us that whatever was going on is now over. We can finalize the work at that point and dispose any resources that might have been used in processing the sequence.

Unfortunately, the universe is not governed by the order, rather by the chaos. Unexpected things happen and we have to anticipate that. For example, a network request can fail so instead of a response, we can receive an error.

```
---!Error!--->
```

In order to represent errors in our sequences, we will introduce yet another kind of event. We will call it a failure event. Failure event will be generated when something unexpected happens. Just like the completion event, failure event will also represent the end of a sequence. No event shall follow the failure event.

Let us see how the event is defined in ReactiveKit.

```swift
/// An event of a sequence.
public enum Event<Element, Error: Swift.Error> {

  /// An event that carries next element.
  case next(Element)

  /// An event that represents failure. Carries an error.
  case failed(Error)

  /// An event that marks the completion of a sequence.
  case completed
}
```

It is just an enumeration of the three kinds of events we have. Sequences will usually have zero or more `.next` events followed by either a `.completed` or a `.failed` event.

What about sequences? In ReactiveKit they are called *signals*. Here is the protocol that defines them.

```swift
/// Represents a sequence of events.
public protocol SignalProtocol {

  /// The type of elements generated by the signal.
  associatedtype Element

  /// The type of error that can terminate the signal.
  associatedtype Error: Swift.Error

  /// Register the given observer.
  /// - Parameter observer: A function that will receive events.
  /// - Returns: A disposable that can be used to cancel the observation.
  public func observe(with observer: @escaping Observer<Element, Error>) -> Disposable
}
```

A signal represents the sequence of events. The most important thing you can do on the sequence is observe the events it generates. Events are received by the *observer*. An observer is nothing more than a function that accepts an event.

```swift
/// Represents a type that receives events.
public typealias Observer<Element, Error: Swift.Error> = (Event<Element, Error>) -> Void
```

## Signals

We have seen the protocol that defines signals, but what about the implementation? Let us implement a basic signal type!

```swift
public struct Signal<Element, Error: Swift.Error>: SignalProtocol {

  private let producer: (Observer<Element, Error>) -> Void

  public init(producer: @escaping (Observer<Element, Error>) -> Void) {
    self.producer = producer
  }

  public func observe(with observer: @escaping Observer<Element, Error>) {
    producer(observer)
  }
}
```

We have defined our signal as a struct of one property - a producer. As you can see, producer is just a function that takes the observer as an argument. When we start observing the signal, what we do is basically execute the producer with the given observer. That is how simple signals are!

> Signal in ReactiveKit is implemented almost like what we have shown here. It has few additions that give us some guarantees that we will talk about later.

Let us create an instance of the signal that sends first three positive integers to the observer and then completes.

Visually that would look like:

```
---[1]---[2]---[3]---|--->
```

While in the code, we would do:

```swift
let counter = Signal<Int, NoError> { observer in

  // send first three positive integers
  observer(.next(1))
  observer(.next(2))
  observer(.next(3))

  // send completed event
  observer(.completed)
}
```

Since the observer is just a function that receives events, we just execute it with the event whenever we want to send a new one. We always finalize the sequence by sending either `.completed` or `.failed` event so that the receiver knows when the signal is over with event production.

ReactiveKit wraps the observer into a struct with various helper methods to make it easier to send events. Here is a protocol that defines it.

```swift
/// Represents a type that receives events.
public protocol ObserverProtocol {

  /// Type of elements being received.
  associatedtype Element

  /// Type of error that can be received.
  associatedtype Error: Swift.Error

  /// Send the event to the observer.
  func on(_ event: Event<Element, Error>)
}
```

Our observer we introduced earlier is basically the `on(_:)` method. ReactiveKit also provides this extensions on the observer:

```swift
public extension ObserverProtocol {

  /// Convenience method to send `.next` event.
  public func next(_ element: Element) {
    on(.next(element))
  }

  /// Convenience method to send `.failed` event.
  public func failed(_ error: Error) {
    on(.failed(error))
   }

  /// Convenience method to send `.completed` event.
  public func completed() {
    on(.completed)
  }

  /// Convenience method to send `.next` event followed by a `.completed` event.
  public func completed(with element: Element) {
    next(element)
    completed()
  }
}
```

So with ReactiveKit we can implement previous example like this:

```swift
let counter = Signal<Int, NoError> { observer in

  // send first three positive integers
  observer.next(1)
  observer.next(2)
  observer.next(3)

  // send completed event
  observer.completed()
}
```

What happens when we observe such signal? Remember, the observer is a function that receives events so we can just pass a closure to our observe method.

```swift
counter.observe(with: { event in
  print(event)
})
```

Of course, we will get our three events printed out.

```swift
next(1)
next(2)
next(3)
completed
```

### Wrapping asynchronous calls into signals

We can easily wrap asynchronous calls into signals because of the way we implemented our `Signal` type. Let us say that we have an asynchronous function that fetches the user.

```swift
func getUser(completion: (Result<User, ClientError>) -> Void) -> URLSessionTask

```

The function communicates fetch result through a completion closure and a `Result` type whose instance will contain either a user or an error. To wrap this into a signal, all we need to do is call that function within our signal initializer's producer closure and send relevant events as they happen.


```swift
func getUser() -> Signal<User, ClientError> {
  return Signal { observer in
    getUser(completion: { result in
      switch result {
      case .success(let user):
        observer.next(user)
        observer.completed()
      case .failure(let error):
        observer.failed(error)
    })
  }
}
```

If we now observe this signal, we will get either a user and a completion event

```
---[User]---|--->
```

or an error

```
---!ClientError!--->
```

In code, getting the user would look like:

```swift
let user = getUser()

user.observe { event in
  print(event) // prints ".next(user), .completed" in case of successful response
}
```

Let me ask you one important question here. When is the request to get the user executed, i.e. when is the asynchronous function `getUser(completion:)` called? Think about it.

We call `getUser(completion:)` within our producer closure that we pass to the signal initializer. That closure however is not executed when the signal is created. That means that the code `let user = getUser()` does not trigger the request. It merely creates a signal that knows how to execute the request.

Request is made when we call the `observe(with:)` method because that is the point when our producer closure gets executed. It also means that if we call the `observe(with:)` method more than once, we will call the producer more than once, so we will execute the request more than once. This is a very powerful aspect of signals and we will get back to it later when we will talk about [sharing sequences of events](#sharing-sequences-of-events). For now just remember that each call to `observe(with:)` means that events get produced all over again.

### Disposing signals

Our example function `getUser(completion:)` returns a `URLSessionTask` object. We often do not think about it, but HTTP requests can be cancelled. When the screen gets dismissed, we should probably cancel any ongoing requests. A way to do that is to call `cancel()` on `URLSessionTask` that we used to make the request. How do we handle that with signals?

If you have been reading the code examples carefully, you have probably noticed that we did not correctly conform our `Signal` to `SignalProtocol`. The protocol specifies that the `observe(with:)` method returns something called `Disposable`. A disposable is an object that can cancel the signal observation and any underlying tasks.

Let me give you the definition of a disposable from ReactiveKit.

```swift
public protocol Disposable {

  /// Cancel the signal observation and any underlying tasks.
  func dispose()

  /// Returns `true` if already disposed.
  var isDisposed: Bool { get }
}
```

It has a method to cancel the observation and a property that can tell us if it has been disposed or not. Cancelling the observation is also referred to as *disposing the signal*.

There are various implementations of `Disposable`, but let us focus on the one that is most commonly used in signal creation. When the signal gets disposed, we often want to perform some action to clean up the resources or stop underlying tasks. What a better way to do that then to execute a closure when the the signal gets disposed. Let us implement a disposable that executes a given closure when it gets disposed. We will call it `BlockDisposable`.

```swift
public final class BlockDisposable: Disposable {

  private var handler: (() -> Void)?

  public var isDisposed: Bool {
    return handler == nil
  }

  public init(_ handler: @escaping () -> Void) {
    self.handler = handler
  }

  public func dispose() {
    handler?()
    handler = nil
  }
}
```

Simple enough. It just executes the given closure when the `dispose()` method is called. How do we use such disposable? Well, we will need to improve our signal implementation.

Who should create the disposable? Since the disposable represents a way to communicate the signal cancellation, it is obviously the one who created the signal that should also provide a disposable that can cancel the signal. To do that we will refactor the signal producer to return a disposable. Additionally, we will return that disposable from the `observe(with:)` method so that whoever will be observing the signal can cancel the observation.

```swift
public struct Signal<Element, Error: Swift.Error>: SignalProtocol {

  private let producer: (Observer<Element, Error>) -> Disposable

  public init(producer: @escaping (Observer<Element, Error>) -> Disposable) {
    self.producer = producer
  }

  public func observe(with observer: @escaping Observer<Element, Error>) -> Disposable {
    return producer(observer)
  }
}
```

This means that when we are creating a signal, we also have to provide a disposable. Let us refactor our asynchronous function wrapper signal to provide a disposable.

```swift
func getUser() -> Signal<User, ClientError> {
  return Signal { observer in
    let task = getUser(completion: { result in
      switch result {
      case .success(let user):
        observer.next(user)
        observer.completed()
      case .failure(let error):
        observer.failed(error)
    })

    return BlockDisposable {
      task.cancel()
    }
  }
}
```

We just return an instance of `BlockDisposable` that cancels the task when it gets disposed. We can then get that disposable when observing the signal.

```swift
let disposable = getUser().observe { event in
  print(event)
}
```

When we are no longer interested in signal events, we can just dispose the disposable. It will cancel the observation and cancel network task.

```swift
disposable.dispose()
```

> In actual implementation of `Signal` in ReactiveKit there are additional mechanisms that prevent events from being sent when the signal is disposed so there is a guarantee that no events will be received after the signal is disposed. Any events sent from the producer after the signal is disposed are ignored.

> In ReactiveKit, signals are automatically disposed when they terminate with either a `.completed` or `.failed` event.

### Transforming signals

This is all so good, but why should we do it? What are the benefits? Here comes the most interesting aspect of reactive programming - signal operators.

Operators are functions (i.e. methods) that transform one or more signals into other signals. One of the basic operations on signals is filtering. Say that we have a signal of city names, but we want only the names starting with letter *P*.

```
filter(
---[Berlin]---[Paris]---[London]---[Porto]---|--->
)

--------------[Paris]--------------[Porto]---|--->
```

How could we implement such operator? Very easily.

```swift
extension SignalProtocol {

  /// Emit only elements that pass `isIncluded` test.
  public func filter(_ isIncluded: @escaping (Element) -> Bool) -> Signal<Element, Error> {
    return Signal { observer in
      return self.observe { event in
        switch event {
        case .next(let element):
          if isIncluded(element) {
            observer.next(element)
          }
        default:
          observer(event)
        }
      }
    }
  }
}
```

We have written an extension method on the `SignalProtocol` in which we create a signal. In the created signal's producer we observe *self* - the signal we are filtering - and propagate `.next` events that pass the test. We also propagate completion and failure events in the `default` case.

We use the operator by calling it on a signal.

```swift
cities.filter { $0.hasPrefix("P") }.observe { event in
  print(event) // prints .next("Paris"), .next("Porto"), .completed
}
```

There are many operators on signals. ReactiveKit is basically a collection of signal operators. Let us see another common one.

When observing signals we often do not care about terminal events, all we care about is the elements in `.next` events. We could write an operator that gives us just that.

```swift
extension SignalProtocol {

  /// Register an observer that will receive elements from `.next` events of the signal.
  public func observeNext(with observer: @escaping (Element) -> Void) -> Disposable {
    return observe { event in
      if case .next(let element) = event {
        observer(element)
      }
    }
  }
}
```

It should be pretty straightforward - just propagate the elements from `.next` event and ignore everything else. Now we can do:

```swift
cities.filter { $0.hasPrefix("P") }.observeNext { name in
  print(name) // prints "Paris", "Porto"
}
```

> ReactiveKit also provides `observeFailed` and `observeCompleted` operators when you are interested only in those events.

Writing operators on signals is as simple as writing an extension method. When you need something that is not provided by the framework, just write it by yourself! ReactiveKit is written to be simple to understand. Whenever you are stuck, just look [into the implementation](https://github.com/ReactiveKit/ReactiveKit/blob/master/Sources/SignalProtocol.swift).

### More about errors

We have seen that a signal can terminate with an error. In our `getUser` example, when the network request fails we send `.failed` event. For that reason, our `Signal` type is generic both over the elements it sends and the errors it can fail with. There are, however, situations when signals are guaranteed not to fail, i.e. when they can never send an error. How do we define that?

ReactiveKit provides following type:

```swift
/// An error type that cannot be instantiated. Used to make signals non-failable.
public enum NoError: Error {
}
```

An enum with no cases that conforms to `Swift.Error` protocol. Since it has no cases, we can never make an instance of it. We will use this trick to get the compile-time guarantee that a signal will not fail.

For example, if we try

```swift
let signal = Signal<Int, NoError> { observer in
  ...
  observer.failed(/* What do I send here? */)
  ...
}
```

we will hit the wall because we cannot create an instance of `NoError` so we cannot send `.failed` event. This is a very powerful and important feature because whenever you see a signal whose errors are specialized to `NoError` type you can safely assume that signal will not fail - because it cannot.

Signals that do not fail are very common so ReactiveKit defines a typealias to make their usage simple and consistent.

```swift
public typealias SafeSignal<Element> = Signal<Element, NoError>
```

You are recommend to use `SafeSignal` whenever you have a signal that cannot fail.

> Bindings work only with safe (non-failable) signals.


### Creating simple signals

You will often need a signal that emits just one element and then completes. To make it, use static method `just`.

```swift
let signal = SafeSignal.just(5)
```

That will give you following signal:

```
---5-|--->
```

If you need a signal that fires multiple elements and then completes, you can convert any `Sequence` to a signal with static method `sequence`.

```swift
let signal = SafeSignal.sequence([1, 2, 3])
```
```
---1-2-3-|--->
```

To create a signal that just completes without sending any elements, do


```swift
let signal = SafeSignal<Int>.completed()
```
```
---|--->
```

To create a signal that just fails, do


```swift
let signal = Signal<Int, MyError>.failed(MyError.someError)
```
```
---!someError!--->
```

You can also create a signal that never sends any events (i.e. a signal that never terminates).

```swift
let signal = SafeSignal.never()
```
```
------>
```

Sometimes you will need a signal that sends specific element after certain amount of time passes:

```swift
let signal = SafeSignal.timer(element: 5, time: 60)
```
```
---/60 seconds/---5-|-->
```

Finally, when you need a signal that sends an integer every `interval` seconds, do

```swift
let signal = SafeSignal.interval(5)
```
```
---0---1---2---3---...>
```


### Disposing in a bag

Handling disposables can be cumbersome when doing multiple observation. To simplify it, ReactiveKit provides a type called `DisposeBag`. It is a container into which you can put your disposables. The bag will dispose all disposables that were put into it when it gets deallocated.

```swift
class Example {

  let bag = DisposeBag()

  init() {
    ...
    someSignal
      .observe { ... }
      .dispose(in: bag)

    anotherSignal
      .observe { ... }
      .dispose(in: bag)
    ...
  }
}
```

In the example, instead of handling the disposables, we just put them into a bag by calling `dispose(in:)` method on the disposable. Disposables will then get disposed automatically when the bag gets deallocated. Note that you can also call `dispose()` on the bag to dispose its contents at will.

ReactiveKit provides a bag on `NSObject` and its subclasses out of the box. If you are doing iOS or Mac development you will get a free `bag` on your view controllers and other UIKit objects since all of them are `NSObject` subclasses.

```swift
extension NSObject {
  public var bag: DisposeBag { get }
}
```

If you are like me and do not want to worry about disposing, check out [bindings](#bindings).

### Threading

By default observers receive events on the thread or the queue where the event is sent from.

For example, if we have a signal that is created like

```swift
let someImage = SafeSignal<UIImage> { observer in
  ...
  DispatchQueue.global(qos: .background).async {
    observer.next(someImage)
  }
  ...
}
```

and if we use it to update the image view

```swift
someImage
  .observeNext { image in
    imageView.image = image // called on background queue
  }
  .dispose(in: bag)
```

we will end up with a weird behaviour. We will be setting image from the background queue on an instance of `UIImageView` that is not thread safe - just like the rest of UIKit.

We could set the image in another async dispatch to main queue, but there is a better way. Just use the operator `observeOn` with the queue you want the observer to be called on.

```swift
someImage
  .observeOn(.main)
  .observeNext { image in
    imageView.image = image // called on main queue
  }
  .dispose(in: bag)
```

There is also another side to this. You might have a signal that does some slow synchronous work on whatever thread or queue it is observed on.

```swift
let someData = SafeSignal<Data> { observer in
  ...
  let data = // synchronously load large file
  observer.next(data)
  ...
}
```

We, however, do not want observing that signal to block the UI.

```swift
someData
  .observeNext { data in // blocks current thread
    display(data)
  }
  .dispose(in: bag)
```

We would like to do the loading on another queue. We could dispatch async the loading, but what if we cannot change the signal producer closure because it is defined in a framework or there is another reason we cannot change it. That is when the operator `executeOn` saves the day.

```swift
someData
  .executeOn(.global(qos: .background))
  .observeOn(.main)
  .observeNext { data in // does not block current thread
    display(data)
  }
  .dispose(in: bag)
```

By applying `executeOn` we define where the signal producer gets executed. We usually use it in a combination with `observeOn` to define where the observer receives events.

Note that there are also operators `observeIn` and `executeIn`. Those operators are similar to the ones we described with the difference that they work with execution contexts instead of with dispatch queues. Execution context is a simple abstraction over a thread or a queue. You can see how it is implemented [here](https://github.com/ReactiveKit/ReactiveKit/blob/master/Sources/ExecutionContext.swift).

### Bindings

Bindings are observations with perks. Most of the time you should be able to replace observation with a binding. Consider the following example. Say we have a signal of users

```swift
let presentUserProfile: SafeSignal<User> = ...
```

and we would like to present a profile screen when a user is sent on the signal. Usually we would do something like:

```swift
presentUserProfile.observeOn(.main).observeNext { [weak self] user in
  let profileViewController = ProfileViewController(user: user)
  self?.present(profileViewController, animated: true)
}.dispose(in: bag)
```

But that is ugly! We have to dispatch everything to the main queue, be cautious not to create a retain cycle and ensure that the disposable we get from the observation is handled.

Thankfully there is a better way. We can create an inline binding instead of the observation. Just do the following

```swift
presentUserProfile.bind(to: self) { me, user in
  let profileViewController = ProfileViewController(user: user)
  me.present(profileViewController, animated: true)
}
```

and stop worrying about threading, retain cycles and disposing because bindings take care of all that automatically. Just bind the signal to the target responsible for performing side effects (in our example, to the view controller responsible for presenting a profile view controller). The closure you provide will be called whenever the signal emits an element with both the target and the sent element as arguments.

#### Binding targets

You can bind to targets that conform both to `Deallocatable` and `BindingExecutionContextProvider` protocols.

> You can actually bind to targets that conform only to `Deallocatable` protocol, but then you have to pass the execution context in which to update the target by calling `bind(to:context:setter)`.

Objects that conform to `Deallocatable` provide a signal that can tell us when the object gets deallocated.

```swift
public protocol Deallocatable: class {

  /// A signal that fires `completed` event when the receiver is deallocated.
  var deallocated: SafeSignal<Void> { get }
}
```

ReactiveKit provides conformance to this protocol for `NSObject` and its subclasses out of the box.

How do you conform to `Deallocatable`? The simplest way is conforming to `DisposeBagProvider` instead.

```swift
/// A type that provides a dispose bag.
/// `DisposeBagProvider` conforms to `Deallocatable` out of the box.
public protocol DisposeBagProvider: Deallocatable {

  /// A `DisposeBag` that can be used to dispose observations and bindings.
  var bag: DisposeBag { get }
}

extension DisposeBagProvider {

  public var deallocated: SafeSignal<Void> {
    return bag.deallocated
  }
}
```

As you can see, `DisposeBagProvider` inherits `Deallocatable` and implements it by taking the deallocated signal from the bag. So all that you need to do is provide a `bag` property on your type.

`BindingExecutionContextProvider` protocol provides the execution context in which the object should be updated. Execution context is just a wrapper over a dispatch queue or a thread. You can see how it is implemented [here](https://github.com/ReactiveKit/ReactiveKit/blob/master/Sources/ExecutionContext.swift).

```swift
public protocol BindingExecutionContextProvider {

  /// An execution context used to deliver binding events.
  var bindingExecutionContext: ExecutionContext { get }
}
```

> Bond framework provides `BindingExecutionContextProvider` conformance to various UIKit objects so they can be seamlessly bound to while ensuring the main thread.

You can conform to this protocol by providing execution context.

```swift
extension MyViewModel: BindingExecutionContextProvider {

  public var bindingExecutionContext: ExecutionContext {
    return .immediateOnMain
  }
}
```

`ExecutionContext.immediateOnMain` executes synchronously if the current thread is main, otherwise it makes asynchronous dispatch to main queue. If you want to bind on background queue, you can return `.global(qos: .background)` instead.

> Note that updating UIKit or AppKit objects must always happen from the main thread or queue.

Now we can peek into the binding implementation.

```swift
extension SignalProtocol where Error == NoError {

  @discardableResult
  public func bind<Target: Deallocatable>(to target: Target, setter: @escaping (Target, Element) -> Void) -> Disposable
  where Target: BindingExecutionContextProvider
  {
    return take(until: target.deallocated)
      .observeIn(target.bindingExecutionContext)
      .observeNext { [weak target] element in
        if let target = target {
          setter(target, element)
        }
      }
  }
}
```

First of all, notice `@discardableResult` annotation. It is there because we can safely ignore the returned disposable. The binding will automatically be disposed when the target gets deallocated. That is ensured by the `take(until:)` operator. It propagates events from self until the given signal completes - in our case until `target.deallocated` signal completes. We then just observe in the right context and on each next element update the target using the provided `setter` closure.

> Note also that bindings are implemented only on non-failable signals.

#### Binding to a property

Ok, that was binding to an object, but what about binding to a property? Would it not be easier that instead of doing

```swift
name.bind(to: label) { label, name in
  label.text = name
}
```

we can do something like:

```swift
name.bind(to: label.reactive.text)
```

And, of course, we can - by using the [Bond framework](https://github.com/ReactiveKit/Bond)!

Bond provides a type called `Bond` that acts as a binding target that we can use to make reactive extensions for various properties. Check out its documentation for more info.

### Sharing sequences of events

Whenever we observe a signal, we execute its producer. Consider the following signal:

```swift
let user = Signal { observer in
  print("Fetching user...")
  ...
}
```

If we now do

```swift
user.observe { ... } // prints: Fetching user...
user.observe { ... } // prints: Fetching user...
```

the producer will be called twice and the user will be fetched twice. Same behaviour might sneak by unnoticed in the code like:

```swift
user.map { $0.name }.observe { ... } // prints: Fetching user...
user.map { $0.email }.observe { ... } // prints: Fetching user...
```

You can think of each signal observation as a process of its own. Often this behaviour is exactly what we need, but sometimes we can optimize our code by sharing one sequence to multiple observers. To achieve that, all we need to do is apply the operator `shareReplay(limit:)`.

```swift
let user = user.shareReplay(limit: 1)

user.map { $0.name }.observe { ... } // prints: Fetching user...
user.map { $0.email }.observe { ... } // Does not print anything, but still gets the user :)
```

Argument `limit` specifies how many elements (`.next` events) should be replayed to the observer. Terminal events are always replayed. One element is often all we need. Operator `shareReplay(limit:)` is a combination of two operators. In order to understand it, we will introduce two interesting concepts: subjects and connectable signals.

### Subjects

At the beginning of the document, we defined signal with the `SignalProtocol` protocol. We then implemented a concrete `Signal` type that conformed to that protocol by executing the producer closure for each observation. Producer would sends events to the observer given to the method `observe(with:)`.

Could we have implemented signal differently? Let us try making another kind of a signal - one that is also an observer. We will call it `Subject`. What follows is the simplified implementation of `Subject`  provided by ReactiveKit.

```swift
open class Subject<Element, Error: Swift.Error>: SignalProtocol, ObserverProtocol {

  private var observers: [Observer<Element, Error>] = []

  open func on(_ event: Event<Element, Error>) {
    observers.forEach { $0(event) }
  }

  open func observe(with observer: @escaping Observer<Element, Error>) -> Disposable {
    observers.append(observer)
    return /* a disposable that removes the observer from the array */
  }
}
```

Our new kind of signal, subject, is an observer itself that holds an array of its own observers. When the subject receives an event (when method `on(_:)` is called), the event is just propagated to all registered observers. Observing this subject means adding the given observer into the array of observers.

How do we use such subject?

```swift
let name = Subject<String, NoError>()

name.observeNext { name in print("Hi \(name)!") }

name.on(.next("Jim")) // prints: Hi Jim!

// ReactiveKit provides few extension toon the ObserverProtocol so we can also do:
name.next("Kathryn") // prints: Hi Kathryn!

name.completed()
```

> Note: When using ReactiveKit you should actually use `PublishSubject` instead. It has the same behaviour and interface as `Subject` we defined here - just a different name in order to be consistent with ReactiveX API.

As you can see, we do not have a producer closure, rather we send events to the subject itself. The subject then propagates those events to its own observers.

Subjects are useful when we need to convert actions from imperative world into signals in reactive world. For example, say we needed view controller appearance events as a signal. We can make a subject property and then send events to it from `viewDidAppear` override. Such subject would then represent a signal of view controller appearance events.

```swift
class MyViewController: UIViewController {

  fileprivate let _viewDidAppear = PublishSubject<Void, NoError>()

  override viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    _viewDidAppear.next()
  }
}
```

We could have exposed subject publicly, but then anyone would be able to send events on it. Better approach is to make it fileprivate as we did and then expose it publicly as a signal. It is recommended to put all reactive extensions into an extension of `ReactiveExtensions` type provided by ReactiveKit. Here is how you do it:


```swift
extension ReactiveExtensions where Base: MyViewController {

  var viewDidAppear: SafeSignal<Void> {
    return base._viewDidAppear.toSignal() // convert Subject to Signal
  }
}
```

We can then use our signal like:

```swift
myViewController.reactive.viewDidAppear.observeNext {
  print("view did appear")
}
```

Subjects represent kind of signals that are called *hot signals*. They are called hot because they "send" events regardless if there are observer registered or no. On the other hand, `Signal` type represents kind of signals that are called *cold signal*. Signals of that kind do not produce events until we give them an observer that will receive events.

As you could have inferred from the implementation, observing a subject gives us only the events that are sent after the observer is registered. Any events that might have been sent before the observer became registered will not be received by the observer. Is there a way to solve this? Well, we could buffer the received events and then replay them to new observers. Let us do that in a subclass.

```swift
public final class ReplaySubject<Element, Error: Swift.Error>: Subject<Element, Error> {

  private var buffer: [Event<Element, Error>] = []

  public override func on(_ event: Event<Element, Error>) {
    events.append(event)
    super.on(event)
  }

  public func observe(with observer: @escaping Observer<Element, Error>) -> Disposable {
    buffer.forEach { observer($0) }
    return super.observe(with: observer)
  }
}
```

Again, this is simplified version of the `ReplaySubject` provided by ReactiveKit, but it has everything needed to explain the concept. Whenever an event is received, we put it in the buffer. When the observer gets registered, we then *replay* all events that we have in the buffer. Any future events will be propagated just like in `Subject`.

> Note: `ReplaySubject` provided by ReactiveKit supports limiting the buffer to certain size so it does not grow forever. Usually it will be enough to limit it to just one event by instantiating it with `ReplaySubject(bufferSize: 1)`. Buffer always keeps the latest event and removes older ones.

At this point you might have the idea how to achieve the behaviour of the `shareReplay` operator. We could observe original signal with the replay subject and then observe that subject multiple times. But in order to implement that as an operator and make it opaque to the user, we need to learn about connectable signals.

### Connectable signals

We have see two kinds of signals so far. A `Signal` that produces events only if the observer is registered and a `Subject` that produces events regardless if there are any observers registered. A connectable signals will be third kind of a signal we will implement. This one will start producing events when we call `connect()` on it. Let us define a protocol first.

```swift
/// Represents a signal that is started by calling `connect` on it.
public protocol ConnectableSignalProtocol: SignalProtocol {

  /// Start the signal.
  func connect() -> Disposable
}
```

We will build a connectable signal as a wrapper over any other kind of a signal. We will leverage subjects for the implementation.

```swift
public final class ConnectableSignal<Source: SignalProtocol>: ConnectableSignalProtocol {

  private let source: Source
  private let subject: Subject<Source.Element, Source.Error>

  public init(source: Source, subject: Subject<Source.Element, Source.Error>) {
    self.source = source
    self.subject = subject
  }

  public func connect() -> Disposable {
    return source.observe(with: subject)
  }

  public func observe(with observer: @escaping Observer<Source.Element, Source.Error>) -> Disposable {
    return subject.observe(with: observer)
  }
}
```

We need two things here: a source signal that we are wrapping into a connectable one and a subject that will propagate events from the source to the connectable signal's observers. We will require them in the initializer and save them as properties.

Observing the connectable signal actually means observing the underlying subject. Starting the signal is now trivial - all we need to do is start observing the source signal with the subject (remember - subject is also an observer). That will make events flow from the source into the observers registered to the subject.

We now have all parts to implement `shareReplay(limit:)`. Let us start with `replay(limit:)`.

```swift
extension SignalProtocol {

  /// Ensure that all observers see the same sequence of elements. Connectable.
  public func replay(_ limit: Int = Int.max) -> ConnectableSignal<Self> {
    return ConnectableSignal(source: self, subject: ReplaySubject(bufferSize: limit))
  }
}
```

Trivial enough. Creating a `ConnectableSignal` with `ReplaySubject` ensures that all observers get the same sequence of events and that the source signal is observed only once. The only problem is that the returned signal is a connectable signal so we have to call `connect()` on it in order to start events.

We somehow need to convert connectable signal into a non-connectable one. In order to do that, we need to call connect at the right time and dispose at the right time. What are the right times? It is only reasonable - right time to connect is on the first observation and right time to dispose is when the last observation is disposed.

In order to do this, we will keep a reference count. With each new observer, the count goes up, while on each disposal it goes down. We will connect when count goes from 0 to 1 and dispose when count goes from 1 to 0.  

```swift
public extension ConnectableSignalProtocol {

  /// Convert connectable signal into the ordinary signal by calling `connect`
  /// on the first observation and calling dispose when number of observers goes down to zero.
  public func refCount() -> Signal<Element, Error> {
    // check out: https://github.com/ReactiveKit/ReactiveKit/blob/e781e1d0ce398259ca38cc0d5d0ed6b56d8eab39/Sources/Connectable.swift#L68-L85
   }
}
```

#### Implementing shareReplay operator

Now that we know about subjects and connectable signals, we can implement the operator `shareReplay(limit:)`. It is quite simple:

```swift
/// Ensure that all observers see the same sequence of elements.
public func shareReplay(limit: Int = Int.max) -> Signal<Element, Error> {
  return replay(limit).refCount()
}
```

### Handling signal errors

You might ignore them and delay, but at one point you will need to handle the errors that the signal can fail with.

If the signal has the potential of recovering by retrying the original producer, you can use `retry` operator.

```swift
let image /*: Signal<UIImage, NetworkError> */ = getImage().retry(3)
```

> Imagine how many number of lines would that take in imperative paradigm :)

Operator `retry` will only work sometimes and it will fail eventually. The result of applying the operator is still a failable signal.

How do we convert failable signal into non-failable (safe) signal? We have to handle the error somehow. One way is to recover with a default element.

```swift
let image /*: SafeSignal<UIImage> */ = getImage().recover(with: .placeholder)
```

Now we get `SafeSignal` because the transformed signal will never fail. Any `.failed` event that might occur on original signal will just be replaced with `.next` event containing the default element (placeholder image in our example).

Alternative way to get safe signal is to ignore - suppress - the error. You would do this if you really do not care about the error and nothing bad will happen if you ignore it.

```swift
let image /*: SafeSignal<UIImage> */ = getImage().suppressError(logging: true)
```

It is always a good idea to log the error.

If you need to do alternative logic in case of an error, you would flat map it onto some other signal.

```swift
let image = getImage().flatMapError { error in
  return getAlternativeImage()
}
```

#### Generalized error handling

Sometimes you will want to handle all your signal errors in the same way. Say you are implementing a view model component where you make multiple requests and want to present error message to the user if any of them fails. To do that, you can make use of publish subjects.

```swift
class ViewModel {

  let errors = SafePublishSubject<MyError>() // typealias for PublishSubject<MyError, NoError>

  ...

  someRequest
    .suppressAndFeedError(into: errors) // returns `SafeSignal`
    .observeNext {}

  ...

  otherRequest
    .suppressAndFeedError(into: errors) // returns `SafeSignal`
    .bind(to: ...)

  ...

  errors.bind(to: viewController) { vc, error in
    vc.display(error)
  }
}
```

We used `suppressAndFeedError` operator to propagate all errors into a subject. We then worked with the subject to handle the errors.

### Tracking signal state

Just like with the errors, you might want to track state of signals in a generalized way. Say you wanted to show network activity indicator whenever there is a request in progress. Here is how you would do it:

```swift
class ViewModel {

  let activity = SafePublishSubject<Bool>() // typealias for PublishSubject<Bool, NoError>

  ...

  someRequest
    .feedActivity(into: activity)
    .observeNext {}

  ...

  otherRequest
    .feedActivity(into: activity)
    .bind(to: ...)

  ...

  activity.bind(to: UIApplication.shared) { application, isActive in
    application.isNetworkActivityIndicatorVisible = isActive
  }
}
```

All you need to do is use operator `feedActivity(into:)` to feed the activity into a boolean subject. When the signal starts the operator will send `true` to the subject. When the signal completes, it will send `false`.

#### Single signal state tracking

Say that you have a login button and want to show the spinner in the button while login request is in progress. You could have a subject that tracks the state of the login signal, but there is a better way.

Create a type that will represent signal state.

```swift
enum State<T> {
  case inProgress
  case done(T)
}
```

Then wrap signal elements into this type and start with the case `inProgress`.

```swift
let loggedIn = login.flatMapLatest { username, passoword in
  return apiClient.login(username, password)
    .map { State.done($0) }
    .start(with: .inProgress)
}
```

You can then bind that signal to your view controller and update the button accordingly:

```swift
loggedIn.bind(to: vc) { vc, state in
  switch state {
    case .inProgress:
      vc.loginButton.startSpinner()
    case .done(let user):
      vc.loginButton.stopSpinner()
      vc.presentProfileViewController(for: user)
  }
}
```

### Property

Property wraps mutable state into an object that enables observation of that state. Whenever the state changes, an observer will be notified. Just like the `PublishSubject`, it represents a bridge into the imperative world.

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

### Other common patterns

#### Performing an action on .next event

Say that you have a button that (re)loads a photo in your app. How to implement that in reactive world? First we will need a signal that represents buttons taps. With [Bond](https://github.com/ReactiveKit/Bond) framework you can get that signal just like this:

```swift
let reload /*: SafeSignal<Void> */ = button.reactive.tap
```

The signal will send `.next` event whenever the button is tapped. We would like to load the photo on each such event. In order to do so, we will flat map the reload signal into photo requests.

```swift
let photo = reload.flatMapLatest { _ in
  return apiClient().loadPhoto() // returns Signal<UIImage, NetworkError>
}
```

`photo` will be of whatever type the inner signal was - in our case `Signal<UIImage, NetworkError>`. We can then bind that to the image view:

```swift
photo
  .suppressError(logging: true)  // we can bind only safe signals
  .bind(to: imageView.reactive.image) // using Bond framework
```

What will happen is that whenever the button is tapped a new photo request will be made and the image view's image will be updated.

There are two other operators that flat map signals: `flatMapConcat` and `flatMapMerge`. The difference between the three is in the way they handle propagation of events from the inner signals in case when there are more than one inner signals active. For example, say that user taps reload button before the previous request is finished. What happens?

* `flatMapLatest` will dispose previous signal and start the new one.
* `flatMapConcat` will start new signal, but it will not propagate its events until the previous signal completes.
* `flatMapMerge` will start new signal, but it will propagate events from all signals as they come - regardless what signal started first.

#### Combining multiple signals

Say you had a username and password signals and you would like a signal that tells you if they are both entered so that you can enable a login button. You can use `combineLatest` operator to achieve that.

```swift
let username = usernameLabel.reactive.text
let password = passwordLabel.reactive.text

let canLogIn = combineLatest(username, password) { username, password in
  return !username.isEmpty && !password.isEmpty
}

canLogIn.bind(to: loginButton.reactive.isEnabled)
```

All you have to provide to the operator is the signals and a closure that maps the latest elements from those signals to a new element.

> Reactive extensions are provided by Bond framework.

## Requirements

* iOS 8.0+ / macOS 10.9+ / tvOS 9.0+ / watchOS 2.0+
* Xcode 9

## Installation

Bond framework is optional, but recommended for Cocoa / Cocoa touch development.

> Note: Since v3.7, ReactiveKit is using Swift 4 syntax that compiles under Xcode 9. If you are still using Xcode 8, please do not update to v3.7 and stay on the latest v3.6.x version.

### CocoaPods

```
pod 'ReactiveKit'
pod 'Bond'
```

### Carthage

```
github "ReactiveKit/ReactiveKit"
github "ReactiveKit/Bond"
```

## Communication

* If you'd like to ask a general question, use Stack Overflow or Github issues.
* If you'd like to ask a quick question or chat about the project, try [Gitter](https://gitter.im/ReactiveKit/General).
* If you have found a bug, open an issue or do a pull request with the fix.
* If you have a feature request, open an issue.
* If you want to contribute, submit a pull request (include unit tests).

## Additional Documentation

* [ReactiveGitter](https://github.com/ReactiveKit/ReactiveGitter) - A ReactiveKit demo application.
* [ReactiveKit Reference](http://cocoadocs.org/docsets/ReactiveKit) - Code reference on Cocoadocs.


## License

The MIT License (MIT)

Copyright (c) 2015-2017 Srdan Rasic (@srdanrasic)

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
