//: [Previous](@previous)

import Foundation
import ReactiveKit
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

//: # Creating Signals
//: Uncomment the `observe { ... }` line to explore the behaviour!

SafeSignal(just: "Jim")
//.observe { print($0) }

SafeSignal(just: "Jim after 1 second", after: 1)
//.observe { print($0) }

SafeSignal(sequence: [1, 2, 3])
//.observe { print($0) }

SafeSignal(sequence: [1, 2, 3], interval: 1)
//.observe { print($0) }

SafeSignal(sequence: 1..., interval: 1)
//.observe { print($0) }

SafeSignal(performing: {
    (0...1000).reduce(0, +)
})
//.observe { print($0) }

Signal<String, NSError>(evaluating: {
    if let file = try? String(contentsOf: URL(fileURLWithPath: "list.txt")) {
        return .success(file)
    } else {
        return .failure(NSError(domain: "No such file", code: 0, userInfo: nil))
    }
})
//.observe { print($0) }

Signal(catching: {
    try String(contentsOf: URL(string: "https://pokeapi.co/api/v2/pokemon/ditto/")!, encoding: .utf8)
})
//.observe { print($0) }

Signal<Int, NSError> { observer in
    observer.receive(1)
    observer.receive(2)
    observer.receive(completion: .finished)
    return BlockDisposable {
        print("disposed")
    }
}
//.observe { print($0) }

var didTapReload: () -> Void = {}
let reloadTaps = Signal(takingOver: &didTapReload)

reloadTaps
//.observeNext { print("reload") }

didTapReload()
didTapReload()

//: [Next](@next)
