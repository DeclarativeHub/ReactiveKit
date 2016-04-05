//: Playground - noun: a place where people can play

import ReactiveKit

let numbers = CollectionProperty([2, 3, 1])

let doubleNumbers = numbers.map { $0 * 2 }
let evenNumbers = numbers.filter { $0 % 2 == 0 }
let sortedNumbers = numbers.sort(<)

sortedNumbers.observeNext { changeset in
  print(changeset.collection)
}

numbers.insert(9, atIndex: 1)
numbers.removeLast()
