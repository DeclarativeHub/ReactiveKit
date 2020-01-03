//
//  Atomic.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 06/11/2019.
//  Copyright © 2019 DeclarativeHub. All rights reserved.
//

import Foundation

final class Atomic<T> {

    private var _value: T
    private let lock: NSLocking

    init(_ value: T, lock: NSLocking = NSRecursiveLock()) {
        self._value = value
        self.lock = lock
    }

    var value: T {
        get {
            lock.lock()
            let value = _value
            lock.unlock()
            return value
        }
        set {
            lock.lock()
            _value = newValue
            lock.unlock()
        }
    }

    func mutate(_ block: (inout T) -> Void) {
        lock.lock()
        block(&_value)
        lock.unlock()
    }

    func mutateAndRead(_ block: (T) -> T) -> T {
        lock.lock()
        let newValue = block(_value)
        _value = newValue
        lock.unlock()
        return newValue
    }

    func readAndMutate(_ block: (T) -> T) -> T {
        lock.lock()
        let oldValue = _value
        _value = block(_value)
        lock.unlock()
        return oldValue
    }
}
