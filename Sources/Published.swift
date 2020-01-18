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
    
    private var value: Value
    private var publisher: Publisher?
    private let willChangeSubject = PassthroughSubject<Void, Never>()

    public init(wrappedValue: Value) {
        value = wrappedValue
    }
    
    /// A publisher for properties used with the `@Published` attribute.
    public struct Publisher: SignalProtocol {
        public typealias Element = Value
        public typealias Error = Never

        fileprivate let didChangeSubject: ReplayOneSubject<Value, Never>
        
        public func observe(with observer: @escaping (Signal<Value, Never>.Event) -> Void) -> Disposable {
            self.didChangeSubject.observe(with: observer)
        }
        
        fileprivate init(_ output: Element) {
            self.didChangeSubject = ReplayOneSubject()
            self.didChangeSubject.send(output)
        }
    }
    
    public var wrappedValue: Value {
        get { self.value }
        set {
            self.willChangeSubject.send()
            self.value = newValue
            self.publisher?.didChangeSubject.send(newValue)
        }
    }
    
    public var projectedValue: Publisher {
        mutating get {
            if let publisher = publisher {
                return publisher
            }
            let publisher = Publisher(value)
            self.publisher = publisher
            return publisher
        }
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
