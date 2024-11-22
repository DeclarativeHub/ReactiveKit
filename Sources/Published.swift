//
//  Published.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 07/12/2019.
//  Copyright © 2019 DeclarativeHub. All rights reserved.
//

#if compiler(>=5.1)

@propertyWrapper
public struct Published<Value> {
    
    private let publisher: Publisher
    private let willChangeSubject = PassthroughSubject<Void, Never>()

    public init(wrappedValue: Value) {
        publisher = Publisher(wrappedValue)
    }
    
    /// A publisher for properties used with the `@Published` attribute.
    public struct Publisher: SignalProtocol {
        public typealias Element = Value
        public typealias Error = Never

        fileprivate let property: Property<Value>
        
        public func observe(with observer: @escaping (Signal<Value, Never>.Event) -> Void) -> Disposable {
            self.property.observe(with: observer)
        }
        
        fileprivate init(_ output: Element) {
            self.property = Property(output)
        }
    }
    
    public var wrappedValue: Value {
        get { self.publisher.property.value }
        nonmutating set {
            self.willChangeSubject.send()
            self.publisher.property.value = newValue
        }
    }
    
    public var projectedValue: Publisher {
        get { publisher }
    }
}

protocol _MutablePropertyWrapper {
    var willChange: Signal<Void, Never> { mutating get }
}

extension Published: _MutablePropertyWrapper {

    var willChange: Signal<Void, Never> {
        mutating get {
            return willChangeSubject.toSignal()
        }
    }
}

#endif
