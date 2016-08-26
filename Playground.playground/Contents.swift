//: Playground - noun: a place where people can play

import ReactiveKit

let s = Signal1.sequence([1, 2, 3])

s.observeNext { (number) in
  print(number)
}
