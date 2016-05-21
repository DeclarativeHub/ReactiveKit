![](Assets/logo.png)

[![Platform](https://img.shields.io/cocoapods/p/ReactiveKit.svg?style=flat)](http://cocoadocs.org/docsets/ReactiveKit/2.0.0-beta4/)
[![Build Status](https://travis-ci.org/ReactiveKit/ReactiveKit.svg?branch=master)](https://travis-ci.org/ReactiveKit/ReactiveKit)
[![Join Us on Gitter](https://img.shields.io/badge/GITTER-join%20chat-blue.svg)](https://gitter.im/ReactiveKit/General)
[![Twitter](https://img.shields.io/badge/twitter-@srdanrasic-red.svg?style=flat)](https://twitter.com/srdanrasic)

__ReactiveKit__ is a collection of Swift frameworks for reactive and functional reactive programming.

* [ReactiveKit](https://github.com/ReactiveKit/ReactiveKit) - A Swift Reactive Programming Kit.
* [ReactiveUIKit](https://github.com/ReactiveKit/ReactiveUIKit) - UIKit extensions that enable bindings.
* [ReactiveAlamofire](https://github.com/ReactiveKit/ReactiveAlamofire) - Reactive extensions for Alamofire framework.

## Reactive Programming

Apps transform data. They take some data as input or generate data by themselves, transform that data into another data and output new data to the user. An app could take computer-friendly response from an API, transform it to a user-friendly text with a photo or video and render an article to the user. An app could take readings from the magnetometer, transform them into an orientation angle and render a nice needle to the user. There are many examples, but the pattern is obvious.

Basic premise of reactive programming is that the output should be derived from the input in such way that whenever the input changes, the output is changed too. Whenever new magnetometer readings are received, needle is updated. In addition to that, if the input is derived into the output using functional constructs like pure or higher-order functions one gets functional reactive programming.

ReactiveKit is a framework that provides mechanisms for leveraging functional reactive paradigm. It's based on ReactiveX API, but with flavours of its own. Instead of one *Observable* type, ReactiveKit offers two types, *Operation* and *Stream*, that are same on all fronts except that the former **can error-out** and the latter **cannot**. ReactiveKit also provides weak binding mechanism as well as reactive collection types.

## Stream

Main type that ReactiveKit provides is `Stream`. It's used to represent a stream of events. Event can be anything from a button tap to a voice command.

Stream event is defined by `StreamEvent` type and looks like this:

```swift
public enum StreamEvent<T> {
  case Next(T)
  case Completed
}
```

Valid streams produce zero or more `.Next` events and always complete with `.Completed` event. Each `.Next` event contains an associated element - the actual value or object produced by the stream.

### Creating Streams

There are many ways to create streams. Main one is by using the constructor that accepts a producer closure. The closure has one argument - an observer to which you send events. To send next element, use `next` method of the observer. When there are no more elements to be generated, send completion event using `completed` method. For example, to create a stream that produces first three positive integers do:

```swift
let counter = Stream<Int> { observer in

  // send first three positive integers
  observer.next(1)
  observer.next(2)
  observer.next(3)

  // complete
  observer.completed()

  return NotDisposable
}
```

> Producer closure expects you to return a disposable. More about disposables can be found [here](#cancellation).

This is just an example of how to manually create streams. In reality, when you need to convert sequence to a stream, you will use following constructor.

```swift
let counter = Stream.sequence([1, 2, 3])
```

To create a stream that produces an integer every second, do

```swift
let counter = Stream<Int>.interval(1, queue: Queue.main)
```

> Note that this constructor requires a queue on which the events will be produced.

For more constructors, refer to the code reference.

### Observing Streams

Stream is only useful if it's being observed. To observe stream, use `observe` method:

```swift
counter.observe { event in
  print(event)
}
```

That will print following:

```
Next(1)
Next(2)
Next(3)
Completed
```

Most of the time we are interested only in the elements that the stream produces. Elements are associated with `.Next` events and to observe just them you do:

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

> Observing the stream actually starts the production of events. In other words, that producer closure we passed in the constructor is called only when you register an observer. If you register more that one observer, producer closure will be called once for each of them.

> Observers will be by default invoked on the thread (queue) on which the producer generates events. You can change that behaviour by passing another [execution context](#threading) using the `observeOn` method.

### Transforming Streams

Streams can be transformed into another streams. Methods that transform streams are often called _operators_. For example, to convert our stream of positive integers into a stream of positive even integers we can do

```swift
let evenCounter = counter.map { $0 * 2 }
```

or to convert it to a stream of integers divisible by three

```swift
let divisibleByThree = counter.filter { $0 % 3 == 0 }
```

or to convert each element to another stream that just triples that element and merge those new streams by concatenating them one after another 

```swift
let tripled = counter.flatMap(.Concat) { number in
  return Stream.sequence(Array(count: 3, repeatedValue: number))
}
``` 

and so on... There are many operators available. For more info on them, check out code reference.

### Sharing Results

Whenever the observer is registered, the stream producer is executed all over again. To share results of a single execution, use `shareReplay` method.

```swift
let sharedCounter = counter.shareReplay()
```

### <a name="cancellation"></a> Cancellation

Observing the stream returns a disposable object. When the disposable object gets disposed, it will notify the producer to stop producing events and also disable further event dispatches.

If you do

```swift
let disposable = aStream.observeNext(...)
```

and later need to cancel the stream, just call `dispose`.

```swift
disposable.dispose()
```

From that point on the stream will not send any more events and the underlying task will be cancelled.

### Bindings

Streams cannot fail and that makes them safe to represent the data that UI displays. To facilitate that use, streams are made to be bindable. They can be bound to any type conforming to `BindableType` protocol.

ReactiveUIKit framework extends various UIKit objects with bindable properties. For example, given

```swift
let name: Stream<String> = ...
```

you can do

```swift
name.bindTo(nameLabel.rText)
```

Actually, because it's only natural to bind text to a label, you can do:

```swift
name.bindTo(nameLabel)
```

> Bindable properties provided by ReactiveUIKit will update the target object on the main thread (queue) by default. That means that the stream can generate events on a background thread without you worrying how the UI will be updated - it will always happen on the main thread.

Bindings will automatically dispose themselves (i.e. cancel source streams) when the binding target gets deallocated. For example, if we do 

```swift
blurredImage().bindTo(imageView)
```

then the image processing will be automatically cancelled if the image view gets deallocated. Isn't that cool!

### Hot Streams

If you need hot streams, i.e. streams that can generate events regardless of the observers, you can use `PushStream` type:

```swift
let numbers = PushStream<Int>()

numbers.observerNext { num in
  print(num)
}

numbers.next(1) // prints: 1
numbers.next(2) // prints: 2
...
```

## Operation

Another important type provided by ReactiveKit is `Operation`. It's just like the `Stream`, but the one that can error-out. Operations are used to represents tasks that can fail like fetching a network resource, reading a file and similar. Operations error-out by sending failure event. Here is how `OperationEvent` type is defined:

```swift
public enum OperationEvent<T, E: ErrorType> {
  case Next(T)
  case Failure(E)
  case Completed
}
```

Valid operations produce zero or more `.Next` events and always terminate with either a `.Completed` event or a `.Failure` event.

Operations can be created, transformed and observed like streams. Additionally, `Operation` provides few additional methods to handle errors.

One way to try to recover from an error is to just retry the operation again. To do so, just do

```swift
let betterFetch = fetchImage(url: ...).retry(3)
```

and smile thinking about how many number of lines would that take in the imperative paradigm.

Errors that cannot be handled with retry will happen eventually. To recover from those, you can use `flatMapError`. It's an operator that maps an error into another operation.

```swift
fetchCurrentUser(token)
  .flatMapError { error in
    return Operation.just(User.Anonymous)
  }
  .observeNext { user in
    print("Authenticated as \(user.fullname).")
  }
```

### Converting Operations to Streams

Operations are not bindable so at one point you'll want to convert them to streams. Worst way to do so is to just ignore and log any error that happens:

```swift
let image = fetchImage(url: ...).toStream(logError: true)
```

Better way is to provide a default value in case of an error:

```swift
let image = fetchImage(url: ...).toStream(recoverWith: Assets.placeholderImage)
```

Most powerful way is to `flatMapError` into another stream:

```swift
let image = fetchImage(url: ...).flatMapError { error in
  return Stream<UIImage> ...
}
```

There is no best way. Errors suck.

## Property

Property wraps mutable state into an object that enables observation of that state. Whenever the state changes, an observer can be notified.

To create the property, just initialize it with the initial value.

```swift
let name = Property("Jim")
```

> `nil` is valid value for properties that wrap optional type.

Properties are streams just like streams of `Stream` type. They can be transformed into another streams, observed and bound in the same manner as streams can be.

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


## Collection Property

When working with collections knowing that the collection changed is usually not enough. Often we need to know how exactly did the collection change - what elements were updated, what inserted and what deleted. `CollectionProperty` enables exactly that. It wraps a collection in order to provide mechanisms for observation of fine-grained changes done to the collection itself. Events generated by collection property contain both the new state of the collection (the collection itself) plus the information about what elements were inserted, updated or deleted.

To provide collection property, just initialize it with the initial value. The type of the value you provide determines the type of the collection property. You can provide an array, a dictionary or a set.


```swift
let uniqueNumbers = CollectionProperty(Set([0, 1, 2]))
```

```swift
let options = CollectionProperty(["enabled": "yes"])
```

```swift
let names: CollectionProperty(["Steve", "Tim"])
```

When observing collection property, events you receive will be structs that contain detailed description of changes that happened.

```swift
names.observeNext { e in
  print("array: \(e.collection), inserts: \(e.inserts), updates: \(e.updates), deletes: \(e.deletes)")
}
```

You work with the collection property like you'd work with the collection it encapsulates.

```swift
names.append("John") // prints: array ["Steve", "Tim", "John"], inserts: [2], updates: [], deletes: []
names.removeLast()   // prints: array ["Steve", "Tim"], inserts: [], updates: [], deletes: [2]
names[1] = "Mark"    // prints: array ["Steve", "Mark"], inserts: [], updates: [1], deletes: []
```

Collection properties can be mapped, filtered and sorted. Let's say we have following collection property:

```swift
let numbers = CollectionProperty([2, 3, 1])
```

When we then do this:

```
let doubleNumbers = numbers.map { $0 * 2 }
let evenNumbers = numbers.filter { $0 % 2 == 0 }
let sortedNumbers = numbers.sort(<)
```

Modifying `numbers` will automatically update all derived arrays:

```swift
numbers.append(4)

Assert(doubleNumbers.collection == [4, 6, 2, 8])
Assert(evenNumbers.collection == [2, 4])
Assert(sortedNumbers.collection == [1, 2, 3, 4])
```

That enables us to build powerful UI bindings. With ReactiveUIKit, collection property containing an array can be bound to `UITableView` or `UICollectionView`. Just provide a closure that creates cells to the `bindTo` method.

```swift
let posts: CollectionProperty <[Post]> = ...

posts.bindTo(tableView) { indexPath, posts, tableView in
  let cell = tableView.dequeueCellWithIdentifier("PostCell", forIndexPath: indexPath) as! PostCell
  cell.post = posts[indexPath.row]
  return cell
}
```

Subsequent changes done to the `posts` array will then be automatically reflected in the table view.

To bind observable dictionary or set to table or collection view, first you have to convert it to the observable array. Because sorting any collection outputs an array, just do that.

```swift
let sortedOptions = options.sort {
  $0.0.localizedCaseInsensitiveCompare($1.0) == NSComparisonResult.OrderedAscending
}
```

The resulting `sortedOptions` is of type `ObservableCollection<[(String, String)]>` - an observable array of key-value pairs sorted alphabetically by the key that can be bound to a table or collection view.

> Same threading rules apply for observable collection bindings as for observable bindings. You can safely modify the collection from a background thread and be confident that the UI updates occur on the main thread. 

### Array diff

When you need to replace an array with another array, but need an event to contains fine-grained changes (for example to update table/collection view with nice animations), you can use method `replace:performDiff:`. For example, if you have

```swift
let numbers: CollectionProperty([1, 2, 3])
```

and you do

```swift
numbers.replace([0, 1, 3, 4], performDiff: true)
```

then the observed event will contain:

```swift
Assert(event.collection == [0, 1, 3, 4])
Assert(event.inserts == [0, 3])
Assert(event.deletes == [1])
```

If that array was bound to a table or a collection view, the view would automatically animate only the changes from the *merge*. Helpful, isn't it.


## <a name="threading"></a>Threading

ReactiveKit uses simple concept of execution contexts inspired by [BrightFutures](https://github.com/Thomvis/BrightFutures) to handle threading.

When you want to receive events on a specific dispatch queue, just use `context` extension of dispatch queue wrapper type `Queue`, for example: `Queue.main.context`, and pass it to the `observeOn` stream operator.

## Reactive Delegates

ReactiveKit provides NSObject extensions that makes it easy to convert delegate pattern into streams. 

First make an extension on your type, UITableView in the following example, that provides a reactive delegate proxy:

```swift
extension UITableView {
  public var rDelegate: ProtocolProxy {
    return protocolProxyFor(UITableViewDelegate.self, setter: NSSelectorFromString("setDelegate:"))
  }
}
```

You can then convert methods of that protocol into streams:

```swift
extension UITableView {
  var selectedRow: Stream<Int> {
    return rDelegate.streamFor(#selector(UITableViewDelegate.tableView(_:didSelectRowAtIndexPath:))) { (_: UITableView, indexPath: NSIndexPath) in indexPath.row }
  }
}
```

Method `streamFor` takes two parameters: a selector to convert to a stream and a mapping closure that maps selector method arguments into a stream.

Now you can do:

```swift
tableView.selectedRow.observeNext { row in
  print("Tapped row at index \(row).")
}.disposeIn(rBag)
```

Protocol proxy takes up delegate slot of the object so if you also need to implement delegate methods manually, don't set `tableView.delegate = x`, rather set `tableView.rDelegate.forwardTo = x`.

Protocol methods that return values are usually used to query data. Such methods can be set up to be fed from a property type. For example:

```swift
let numberOfItems = Property(12)

tableView.rDataSource.feed(
  numberOfItems,
  to: #selector(UITableViewDataSource.tableView(_:numberOfRowsInSection:)),
  map: { (value: Int, _: UITableView, _: Int) -> Int in value }
)
```

Method `feed` takes three parameters: a property to feed from, a selector, and a mapping closure that maps from the property value and selector method arguments to the selector method return value. 

You should not set more that one feed property per selector.

Note that in the mapping closures of both `streamFor` and `feed` methods you must be explicit about argument and return types. You must also use ObjC types as this is ObjC API. For example, use `NSString` instead of `String`. 

## Requirements

* iOS 8.0+ / OS X 10.9+ / tvOS 9.0+ / watchOS 2.0+
* Xcode 7.3+

## Communication

* If you'd like to ask a general question, use Stack Overflow.
* If you'd like to ask a quick question or chat about the project, try [Gitter](https://gitter.im/ReactiveKit/General).
* If you found a bug, open an issue.
* If you have a feature request, open an issue.
* If you want to contribute, submit a pull request (include unit tests).
* You can track project plan and progress on [Waffle](https://waffle.io/ReactiveKit/ReactiveKit).

## Additional Documentation

* [ReactiveGitter](https://github.com/ReactiveKit/ReactiveGitter) - A ReactiveKit demo application.
* [ReactiveKit Reference](http://cocoadocs.org/docsets/ReactiveKit/2.0.0) - Code reference on Cocoadocs.

## Installation

### CocoaPods

```
pod 'ReactiveKit', '~> 2.0'
pod 'ReactiveUIKit', '~> 2.0'
```

### Carthage

```
github "ReactiveKit/ReactiveKit" ~> 2.0
github "ReactiveKit/ReactiveUIKit" ~> 2.0
```

## Migration

### Migration from v1.x to v2.0

* `Observable` is renamed to `Property`
* `ObservableCollection` is renamed to `CollectionProperty`
* `Stream` can now completable (with `.Completed` event)
* `observe` method of `Stream` is renamed to `observeNext`
* `shareNext` is renamed to `shareReplay`.
* `Stream` and `Operation` now have consistent API-s
* `Operation`is no longer bindable. Convert it to `Stream` first.
* Execution context can now be set only using `executeOn` and `observeOn` methods. 
* A number of new operators is introduced based on ReactiveX API.
* Project is restructured and should be available as a Swift package.
* Documentation is updated to put `Stream` type in focus.
* ReactiveFoundation is now part of ReactiveKit.

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
