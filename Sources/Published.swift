//
//  Published.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 07/12/2019.
//  Copyright © 2019 DeclarativeHub. All rights reserved.
//

#if compiler(>=5.1)

import Foundation

internal protocol PublishedProtocol {
    var willChangeSubject: PassthroughSubject<Void, Never> { get }
}

@propertyWrapper
public struct Published<Value>: PublishedProtocol {

    internal let willChangeSubject = PassthroughSubject<Void, Never>()
    internal let property: Property<Value>

    public init(wrappedValue: Value) {
        property = Property(wrappedValue)
    }

    public var wrappedValue: Value {
        get {
            return property.value
        }
        nonmutating set {
            willChangeSubject.send()
            property.value = newValue
        }
    }

    public var projectedValue: Signal<Value, Never> {
        return property.toSignal()
    }
}

#endif
