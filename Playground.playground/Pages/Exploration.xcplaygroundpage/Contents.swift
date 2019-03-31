//: Playground - noun: a place where people can play

import ReactiveKit
import PlaygroundSupport

//: Explore ReactiveKit here

enum MyError: Error {
    case unknown
}

let a = Signal<Int, Error>(sequence: 0...4, interval: 0.5)
let b = SafeSignal(sequence: 0...2, interval: 2)

b.concat(with: b)

