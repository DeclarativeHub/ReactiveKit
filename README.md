# rKit - A Swift Reactive Programming Kit

__rKit__ is a collection of Swift frameworks for reactive and functional reactive programming.

* [rKit](https://github.com/ReactiveKit/rKit) - A core framework that provides cold Stream and hot ActiveStream types and their derivatives -  Tasks, Observable and ObservableCollection types.
* [rFoundation](https://github.com/ReactiveKit/rFoundation) - Foundation framework extensions like type-safe KVO.
* [rUIKit](https://github.com/ReactiveKit/rUIKit) - UIKit extensions (bindings).

## Observable

`Observable` type represents observable mutable state, like a variable whose changes can be observed.

```swift
let name = Observable("Jim")

name.observe { value in
  print(value)
}

name.value = "Jim Kirk" // prints: Jim Kirk

name.bindTo(nameLabel.rText)
```

## Task

`Task` type is used to represents asynchronous work that can fail.

```swift
func fetchImage() -> Task<UIImage, NSError> {

  return create { sink in
    ...
    sink.next(image)
    sink.success()
    ...
  }
}


fetchImage().observeNext(on: Queue.Main.contex) { image in
  ...
}

fetchImage().bindTo(imageView.rImage)

```

Each call to task's `observe` method performs separate work. To share results of a single call, use a `shareNext` method.

```swift
let image = fetchImage().shareNext(on: Queue.Main.context)

image.bindTo(imageView1)
image.bindTo(imageView2)
```

## Streams

Both Task and Observable are streams that conform to `StreamType` protocol. Streams can be transformed, for example:

```swift
func fetchAndBlurImage() -> Task<UIImage, NSError> {
  return fetchImage().map { $0.applyBlur() }
}

```

## ObservableCollection

`ObservableCollection` is a stream that can be used to encapsulate a collection (array, dictionary or set) and send fine-grained events describing changes that occured. 

```swift
let names: ObservableCollection(["Steve", "Tim"])

names.observe { event in
  print(event.inserts)
}

names.append("John") // prints: [2]
```

## Installation

### Carthage

```
github "ReactiveKit/rKit" 
github "ReactiveKit/rUIKit"
github "ReactiveKit/rFoundation"
```


## License

The MIT License (MIT)

Copyright (c) 2015 Srdan Rasic (@srdanrasic)

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