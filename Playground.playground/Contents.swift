//: Playground - noun: a place where people can play

import ReactiveKit
import PlaygroundSupport

var p: Property! = Property(1)
weak var wp: Property<Int>? = p

SafeSignal<Double>.interval(1, queue: .main).map { $0 }.debug("test signal").bind(to: p)

DispatchQueue.main.after(when: 3.3) {
  p = nil
  wp
}

PlaygroundPage.current.needsIndefiniteExecution = true
