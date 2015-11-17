//
//  OperationSpec.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 06/11/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

import Quick
import Nimble
@testable import ReactiveKit

enum TestError: ErrorType {
  case ErrorA
  case ErrorB
}

class OperationSpec: QuickSpec {
  
  override func spec() {
    
    describe("a successful operation") {
      var operation: Operation<Int, TestError>!
      var simpleDisposable: SimpleDisposable!
      
      beforeEach {
        operation = create { observer in
          observer.next(1)
          observer.next(2)
          observer.next(3)
          observer.success()
          simpleDisposable = SimpleDisposable()
          return simpleDisposable
        }
      }
      
      context("observeNext") {
        var observedEvents: [Int] = []
        var disposable: DisposableType!
        
        beforeEach {
          disposable = operation.observeNext(on: ImmediateExecutionContext) {
            observedEvents.append($0)
          }
        }
        
        it("generates values") {
          expect(observedEvents) == [1, 2, 3]
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(simpleDisposable.isDisposed).to(beTrue())
          }
        }
      }
      
      context("map") {
        var observedEvents: [Int] = []
        var disposable: DisposableType!
        
        beforeEach {
          disposable = operation.map { $0 * 2 }.observeNext(on: ImmediateExecutionContext) {
            observedEvents.append($0)
          }
        }
        
        it("generates mapped values") {
          expect(observedEvents) == [2, 4, 6]
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(simpleDisposable.isDisposed).to(beTrue())
          }
        }
      }
      
      context("zipWith") {
        var observedEvents: [(Int, Int)] = []
        var disposable: DisposableType!
        let otherSimpleDisposable = SimpleDisposable()
        
        beforeEach {
          let otherOperation: Operation<Int, TestError> = create { observer in
            observer.next(10)
            observer.next(20)
            observer.next(30)
            observer.next(40)
            observer.success()
            return otherSimpleDisposable
          }
          
          disposable = operation.zipWith(otherOperation).observeNext(on: ImmediateExecutionContext) {
            observedEvents.append($0)
          }
        }
        
        it("does zip") {
          expect(observedEvents[0].0) == 1
          expect(observedEvents[0].1) == 10
          expect(observedEvents[1].0) == 2
          expect(observedEvents[1].1) == 20
          expect(observedEvents[2].0) == 3
          expect(observedEvents[2].1) == 30
          expect(observedEvents.count) == 3
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(simpleDisposable.isDisposed).to(beTrue())
          }
          
          it("other is disposed") {
            expect(otherSimpleDisposable.isDisposed).to(beTrue())
          }
        }
      }
    }
    
    describe("merge") {
      var outerDisposable: SimpleDisposable!
      var innerDisposable1: SimpleDisposable!
      var innerDisposable2: SimpleDisposable!

      var outerProducer: ActiveStream<OperationEvent<Int, TestError>>!
      var innerProducer1: ActiveStream<OperationEvent<Int, TestError>>!
      var innerProducer2: ActiveStream<OperationEvent<Int, TestError>>!
      
      var operation: Operation<Int, TestError>!
      
      var observedValues: [Int]!
      var observedErrors: [TestError]!
      var observedSuccesses: Int!
      var disposable: DisposableType!

      beforeEach {
        observedValues = []
        observedErrors = []
        observedSuccesses = 0
        
        outerDisposable = SimpleDisposable()
        innerDisposable1 = SimpleDisposable()
        innerDisposable2 = SimpleDisposable()
        
        outerProducer = ActiveStream<OperationEvent<Int, TestError>>(limit: 0, producer: { s in outerDisposable })
        innerProducer1 = ActiveStream<OperationEvent<Int, TestError>>(limit: 0, producer: { s in innerDisposable1 })
        innerProducer2 = ActiveStream<OperationEvent<Int, TestError>>(limit: 0, producer: { s in innerDisposable2 })
        
        operation = create { observer in
          outerProducer.observe(on: ImmediateExecutionContext) { e in
            observer.observer(e)
          }
          return outerDisposable
        }
        
        disposable = operation
          .flatMap(.Merge) { (v: Int) -> Operation<Int, TestError> in
            if v == 1 {
              return create { observer in
                innerProducer1.observe(on: ImmediateExecutionContext) { e in
                  observer.observer(e)
                }
                return innerDisposable1
              }
            } else {
              return create { observer in
                innerProducer2.observe(on: ImmediateExecutionContext) { e in
                  observer.observer(e)
                }
                return innerDisposable2
              }
            }
          }
          .observe(on: ImmediateExecutionContext) { e in
            switch e {
            case .Next(let value): observedValues.append(value)
            case .Failure(let error): observedErrors.append(error)
            case .Success: observedSuccesses = observedSuccesses + 1
            }
        }
      }
      
      it("not disposed") {
        expect(outerDisposable.isDisposed).to(beFalse())
        expect(innerDisposable1.isDisposed).to(beFalse())
        expect(innerDisposable2.isDisposed).to(beFalse())
      }
      
      context("generates events") {
        
        beforeEach {
          outerProducer.next(.Next(1))
          innerProducer1.next(.Next(10))
          innerProducer1.next(.Next(20))
          outerProducer.next(.Next(2))
          innerProducer1.next(.Next(30))
          innerProducer2.next(.Next(100))
          innerProducer2.next(.Next(200))
          innerProducer1.next(.Next(40))
          innerProducer1.next(.Success)
          innerProducer1.next(.Next(50)) // should not be sent
          innerProducer2.next(.Next(300))
          outerProducer.next(.Success)
          innerProducer2.next(.Next(400)) // inner should still be active
          innerProducer2.next(.Success)
          innerProducer2.next(.Next(500)) // should not be sent
        }
        
        it("generates correct events") {
          expect(observedValues) == [10, 20, 30, 100, 200, 40, 300, 400]
          expect(observedErrors) == []
          expect(observedSuccesses) == 1
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(outerDisposable.isDisposed).to(beTrue())
            expect(innerDisposable1.isDisposed).to(beTrue())
            expect(innerDisposable2.isDisposed).to(beTrue())
          }
        }
      }
      
      context("inner failure") {
        
        beforeEach {
          outerProducer.next(.Next(1))
          outerProducer.next(.Next(2))
          innerProducer1.next(.Failure(.ErrorA))
          innerProducer2.next(.Next(100)) // should not be sent
          innerProducer2.next(.Success)
          outerProducer.next(.Next(1))
          innerProducer1.next(.Next(10)) // should not be sent
        }
        
        it("correct events") {
          expect(observedValues) == []
          expect(observedErrors) == [.ErrorA]
          expect(observedSuccesses) == 0
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(outerDisposable.isDisposed).to(beTrue())
            expect(innerDisposable1.isDisposed).to(beTrue())
            expect(innerDisposable2.isDisposed).to(beTrue())
          }
        }
      }
      
      context("outer failure") {
        
        beforeEach {
          outerProducer.next(.Next(1))
          outerProducer.next(.Next(2))
          innerProducer2.next(.Next(100))
          outerProducer.next(.Failure(.ErrorA))
          innerProducer1.next(.Next(10)) // should not be sent
        }
        
        it("correct events") {
          expect(observedValues) == [100]
          expect(observedErrors) == [.ErrorA]
          expect(observedSuccesses) == 0
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(outerDisposable.isDisposed).to(beTrue())
            expect(innerDisposable1.isDisposed).to(beTrue())
            expect(innerDisposable2.isDisposed).to(beTrue())
          }
        }
      }
    }
    
    describe("switchToLateset") {
      var outerDisposable: SimpleDisposable!
      var innerDisposable1: SimpleDisposable!
      var innerDisposable2: SimpleDisposable!
      
      var outerProducer: ActiveStream<OperationEvent<Int, TestError>>!
      var innerProducer1: ActiveStream<OperationEvent<Int, TestError>>!
      var innerProducer2: ActiveStream<OperationEvent<Int, TestError>>!
      
      var operation: Operation<Int, TestError>!
      
      var observedValues: [Int]!
      var observedErrors: [TestError]!
      var observedSuccesses: Int!
      var disposable: DisposableType!
      
      beforeEach {
        observedValues = []
        observedErrors = []
        observedSuccesses = 0
        
        outerDisposable = SimpleDisposable()
        innerDisposable1 = SimpleDisposable()
        innerDisposable2 = SimpleDisposable()
        
        outerProducer = ActiveStream<OperationEvent<Int, TestError>>(limit: 0, producer: { s in outerDisposable })
        innerProducer1 = ActiveStream<OperationEvent<Int, TestError>>(limit: 0, producer: { s in innerDisposable1 })
        innerProducer2 = ActiveStream<OperationEvent<Int, TestError>>(limit: 0, producer: { s in innerDisposable2 })
        
        operation = create { observer in
          outerProducer.observe(on: ImmediateExecutionContext) { e in
            observer.observer(e)
          }
          return outerDisposable
        }
        
        disposable = operation
          .flatMap(.Latest) { (v: Int) -> Operation<Int, TestError> in
            if v == 1 {
              return create { observer in
                innerProducer1.observe(on: ImmediateExecutionContext) { e in
                  observer.observer(e)
                }
                return innerDisposable1
              }
            } else {
              return create { observer in
                innerProducer2.observe(on: ImmediateExecutionContext) { e in
                  observer.observer(e)
                }
                return innerDisposable2
              }
            }
          }
          .observe(on: ImmediateExecutionContext) { e in
            switch e {
            case .Next(let value): observedValues.append(value)
            case .Failure(let error): observedErrors.append(error)
            case .Success: observedSuccesses = observedSuccesses + 1
            }
        }
      }
      
      it("not disposed") {
        expect(outerDisposable.isDisposed).to(beFalse())
        expect(innerDisposable1.isDisposed).to(beFalse())
        expect(innerDisposable2.isDisposed).to(beFalse())
      }
      
      context("generates events") {
        
        beforeEach {
          outerProducer.next(.Next(1))
          innerProducer1.next(.Next(10))
          outerProducer.next(.Next(2))
          innerProducer1.next(.Next(20))
          innerProducer2.next(.Next(100))
          innerProducer1.next(.Next(30))
          innerProducer1.next(.Success)
          innerProducer1.next(.Next(40))
          innerProducer2.next(.Next(200))
          innerProducer2.next(.Success)
          outerProducer.next(.Next(1))
          outerProducer.next(.Success)
          innerProducer1.next(.Next(10))
          innerProducer1.next(.Success)
        }
        
        it("generates correct events") {
          expect(observedValues) == [10, 100, 200, 10]
          expect(observedErrors) == []
          expect(observedSuccesses) == 1
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(outerDisposable.isDisposed).to(beTrue())
            expect(innerDisposable1.isDisposed).to(beTrue())
            expect(innerDisposable2.isDisposed).to(beTrue())
          }
        }
      }
      
      context("inner failure") {
        
        beforeEach {
          outerProducer.next(.Next(1))
          outerProducer.next(.Next(2))
          innerProducer1.next(.Next(10))
          innerProducer1.next(.Success)
          innerProducer2.next(.Next(100))
          innerProducer2.next(.Failure(.ErrorB))
          outerProducer.next(.Next(1))
          innerProducer1.next(.Next(10))
        }
        
        it("correct events") {
          expect(observedValues) == [100]
          expect(observedErrors) == [.ErrorB]
          expect(observedSuccesses) == 0
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(outerDisposable.isDisposed).to(beTrue())
            expect(innerDisposable1.isDisposed).to(beTrue())
            expect(innerDisposable2.isDisposed).to(beTrue())
          }
        }
      }
      
      context("outer failure") {
        
        beforeEach {
          outerProducer.next(.Next(1))
          outerProducer.next(.Next(2))
          innerProducer2.next(.Next(100))
          outerProducer.next(.Failure(.ErrorA))
          innerProducer1.next(.Next(10)) // should not be sent
        }
        
        it("correct events") {
          expect(observedValues) == [100]
          expect(observedErrors) == [.ErrorA]
          expect(observedSuccesses) == 0
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(outerDisposable.isDisposed).to(beTrue())
            expect(innerDisposable1.isDisposed).to(beTrue())
            expect(innerDisposable2.isDisposed).to(beTrue())
          }
        }
      }
    }

    
    describe("concat") {
      var outerDisposable: SimpleDisposable!
      var innerDisposable1: SimpleDisposable!
      var innerDisposable2: SimpleDisposable!
      
      var outerProducer: ActiveStream<OperationEvent<Int, TestError>>!
      var innerProducer1: ActiveStream<OperationEvent<Int, TestError>>!
      var innerProducer2: ActiveStream<OperationEvent<Int, TestError>>!
      
      var operation: Operation<Int, TestError>!
      
      var observedValues: [Int]!
      var observedErrors: [TestError]!
      var observedSuccesses: Int!
      var disposable: DisposableType!
      
      beforeEach {
        observedValues = []
        observedErrors = []
        observedSuccesses = 0
        
        outerDisposable = SimpleDisposable()
        innerDisposable1 = SimpleDisposable()
        innerDisposable2 = SimpleDisposable()
        
        outerProducer = ActiveStream<OperationEvent<Int, TestError>>(limit: 10, producer: { s in outerDisposable })
        innerProducer1 = ActiveStream<OperationEvent<Int, TestError>>(limit: 10, producer: { s in innerDisposable1 })
        innerProducer2 = ActiveStream<OperationEvent<Int, TestError>>(limit: 10, producer: { s in innerDisposable2 })
        
        operation = create { observer in
          outerProducer.observe(on: ImmediateExecutionContext) { e in
            observer.observer(e)
          }
          return outerDisposable
        }
        
        disposable = operation
          .flatMap(.Concat) { (v: Int) -> Operation<Int, TestError> in
            if v == 1 {
              return create { observer in
                innerProducer1.observe(on: ImmediateExecutionContext) { e in
                  observer.observer(e)
                }
                return innerDisposable1
              }
            } else {
              return create { observer in
                innerProducer2.observe(on: ImmediateExecutionContext) { e in
                  observer.observer(e)
                }
                return innerDisposable2
              }
            }
          }
          .observe(on: ImmediateExecutionContext) { e in
            switch e {
            case .Next(let value): observedValues.append(value)
            case .Failure(let error): observedErrors.append(error)
            case .Success: observedSuccesses = observedSuccesses + 1
            }
        }
      }
      
      it("not disposed") {
        expect(outerDisposable.isDisposed).to(beFalse())
        expect(innerDisposable1.isDisposed).to(beFalse())
        expect(innerDisposable2.isDisposed).to(beFalse())
      }
      
      context("generates events") {
        
        beforeEach {
          outerProducer.next(.Next(1))
          innerProducer1.next(.Next(10))
          outerProducer.next(.Next(2))
          innerProducer1.next(.Next(20))
          innerProducer2.next(.Next(100))
          innerProducer2.next(.Next(200))
          innerProducer1.next(.Next(30))
          innerProducer1.next(.Success)
          outerProducer.next(.Success)
          innerProducer2.next(.Next(300))
          innerProducer2.next(.Success)
        }
        
        it("generates correct events") {
          expect(observedValues) == [10, 20, 30, 100, 200, 300]
          expect(observedErrors) == []
          expect(observedSuccesses) == 1
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(outerDisposable.isDisposed).to(beTrue())
            expect(innerDisposable1.isDisposed).to(beTrue())
            expect(innerDisposable2.isDisposed).to(beTrue())
          }
        }
      }
      
      context("inner failure") {
        
        beforeEach {
          outerProducer.next(.Next(1))
          outerProducer.next(.Next(2))
          innerProducer2.next(.Next(100))
          innerProducer2.next(.Failure(.ErrorB))
          innerProducer1.next(.Next(10))
          innerProducer1.next(.Success)
          outerProducer.next(.Success)
        }
        
        it("correct events") {
          expect(observedValues) == [10, 100]
          expect(observedErrors) == [.ErrorB]
          expect(observedSuccesses) == 0
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(outerDisposable.isDisposed).to(beTrue())
            expect(innerDisposable1.isDisposed).to(beTrue())
            expect(innerDisposable2.isDisposed).to(beTrue())
          }
        }
      }
      
      context("outer failure") {
        
        beforeEach {
          outerProducer.next(.Next(1))
          outerProducer.next(.Next(2))
          innerProducer1.next(.Success)
          innerProducer2.next(.Next(100))
          outerProducer.next(.Failure(.ErrorA))
          innerProducer1.next(.Next(10))
        }
        
        it("correct events") {
          expect(observedValues) == [100]
          expect(observedErrors) == [.ErrorA]
          expect(observedSuccesses) == 0
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(outerDisposable.isDisposed).to(beTrue())
            expect(innerDisposable1.isDisposed).to(beTrue())
            expect(innerDisposable2.isDisposed).to(beTrue())
          }
        }
      }
    }
  }
}
