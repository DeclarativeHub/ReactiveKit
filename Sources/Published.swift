//
//  Published.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 07/12/2019.
//  Copyright © 2019 DeclarativeHub. All rights reserved.
//

#if compiler(>=5.1)

import Foundation

@propertyWrapper
public struct Published<Value> {

    private let property: Property<Value>

    public init(wrappedValue: Value) {
        property = Property(wrappedValue)
    }

    public var wrappedValue: Value {
        get {
            return property.value
        }
        set {
            property.value = newValue
        }
    }

    public var projectedValue: Signal<Value, Never> {
        return property.toSignal()
    }
}

#endif
