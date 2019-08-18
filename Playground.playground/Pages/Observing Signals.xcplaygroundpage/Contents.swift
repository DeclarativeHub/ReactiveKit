//: [Previous](@previous)

import Foundation
import ReactiveKit
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

//: # Observing Signals

// Let's make a signal that simulates doing some work like loading of a large file.

let loadedFile = SafeSignal<String> { observer in
    print("Now loading file...")
    sleep(1)
    observer.completed(with: "first line\nsecond line")
    print("File loaded.")
    return NonDisposable.instance
}

// If you run the playground up to this line, nothing will happen.
// You console log will be empty. Even if we access the signal

_ = loadedFile

// still nothing happens. We could transform it using any of the operators

let numberOfLines = loadedFile
    .map { $0.split(separator: "\n").count }
    .map { "The file has \($0) lines." }

// and if you run the playground up to this line, nothing again.

// While this might be a bit confusing, it's the most powerful feature of signals and
// functional-reactive programming. Signals allow us to express the logic without doing side effects.

// In our example, we've defined how to load a file and how to count number of lines
// in the file, but we have not actually loaded the file nor counted the lines.

// To make side effects, to do the work, one has to observe the signal. It's the act
// of observing that starts everything! Let's try observing the signal.

numberOfLines.observe { event in
    print(event)
}

// Run the playground up to this line and watch the console log.
// It's only now that the file gets loaded, signal transformed and events printed.

// This is very useful in real world development, but be aware of a caveat: observing the
// signal again will repeat the side efects. In our example, the file will be loaded again.

numberOfLines.observe { event in
    print(event)
}

// Bummer? No. Once you get more into functional-reactive parading you will see that
// being able to express the logic without doing side effects outweights this inconvenience.
// In order to share the sequence, all we need to do is apply `shareReplay` operator.

let sharedLoadedFile = loadedFile.share()

// The first time we observe the shared signal, it will load the file:

sharedLoadedFile.observe { print($0) }

// However, any subsequent observation will just use the shared sequence cached in the memory:

sharedLoadedFile.observe { print($0) }
sharedLoadedFile.observe { print($0) }

// There are few convience methods for observing signals. When you are only interested into elements
// of the signal, as opposed to events that contain element, you could just observe next events:

sharedLoadedFile.observeNext { fileContent in
    print(fileContent)
}

// If you are interested only when the signal completes, then observe just the completed event:

sharedLoadedFile.observeCompleted {
    print("Done")
}

// Some signals can fail with an error. When you are interested only in the failure, observe the failed event:

sharedLoadedFile.observeFailed { error in
    print("Failed with error", error) // Will not happen because our signal doesn't fail.
}

//: [Next](@next)
