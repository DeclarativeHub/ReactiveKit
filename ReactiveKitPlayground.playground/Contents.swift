//: Playground - noun: a place where people can play

import ReactiveKit

let s = SafeSignal<Int>.just(22)
s.observeNext { i in
  print(i)
}

//enum MyError: ErrorProtocol {
//  case error(String)
//}
//
//let i = Signal<Either<Int, MyError>> { observer in
//  observer.next(1)
//  observer.next(2)
//  observer.failure(.error("hahaha"))
//
//  return notDisposable
//}
//
//i.observeNext { e in
//  print(e)
//}
//
//i.observeError { error in
//  print(error)
//}
//
//i.observe { e in
//  print(e)
//}

33
333
