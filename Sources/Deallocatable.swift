//
//  Deallocatable.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 17/03/2017.
//  Copyright © 2017 Srdan Rasic. All rights reserved.
//

/// A type that notifies about its own deallocation.
/// 
/// `Deallocatable` can be used as a binding target. For example,
/// instead of observing a signal, one can bind it to a `Deallocatable`.
///
///     class View: Deallocatable { ... }
///     
///     let view: View = ...
///     let signal: SafeSignal<Int> = ...
///
///     signal.bind(to: view) { view, number in
///       view.display(number)
///     }
public protocol Deallocatable: class {
    
    /// A signal that fires `completed` event when the receiver is deallocated.
    var deallocated: SafeSignal<Void> { get }
}

/// A type that provides a dispose bag.
/// `DisposeBagProvider` conforms to `Deallocatable` out of the box.
public protocol DisposeBagProvider: Deallocatable {
    
    /// A `DisposeBag` that can be used to dispose observations and bindings.
    var bag: DisposeBag { get }
}

extension DisposeBagProvider {
    
    /// A signal that fires `completed` event when the receiver is deallocated.
    public var deallocated: SafeSignal<Void> {
        return bag.deallocated
    }
}

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)

import ObjectiveC.runtime

extension NSObject: DisposeBagProvider {
    
    private struct AssociatedKeys {
        static var DisposeBagKey = "DisposeBagKey"
    }
    
    /// A `DisposeBag` that can be used to dispose observations and bindings.
    public var bag: DisposeBag {
        if let disposeBag = objc_getAssociatedObject(self, &NSObject.AssociatedKeys.DisposeBagKey) {
            return disposeBag as! DisposeBag
        } else {
            let disposeBag = DisposeBag()
            objc_setAssociatedObject(self, &NSObject.AssociatedKeys.DisposeBagKey, disposeBag, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return disposeBag
        }
    }
}

#endif
