//
//  ObservableObject.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 07/12/2019.
//  Copyright © 2019 DeclarativeHub. All rights reserved.
//

#if compiler(>=5.1)

import Foundation

/// A type of object with a publisher that emits before the object has changed.
///
/// By default an `ObservableObject` will synthesize an `objectWillChange`
/// publisher that emits before any of its `@Published` properties changes:
public protocol ObservableObject: AnyObject {

    /// The type of signal that emits before the object has changed.
    associatedtype ObjectWillChangeSignal: SignalProtocol = Signal<Void, Never> where Self.ObjectWillChangeSignal.Error == Never

    /// A signal that emits before the object has changed.
    var objectWillChange: Self.ObjectWillChangeSignal { get }
}

extension ObservableObject where Self.ObjectWillChangeSignal == Signal<Void, Never> {

    /// A publisher that emits before the object has changed.
    public var objectWillChange: Signal<Void, Never> {
        var signals: [Signal<Void, Never>] = []
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if var publishedProperty = child.value as? _MutablePropertyWrapper {
                signals.append(publishedProperty.willChange)
            }
        }
        return Signal(flattening: signals, strategy: .merge)
    }
}

#endif
