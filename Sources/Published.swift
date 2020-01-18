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
    
    private var value: Value
    private var publisher: Publisher?
    internal let willChangeSubject = PassthroughSubject<Void, Never>()
    
    public init(wrappedValue: Value) {
        value = wrappedValue
    }
    
    /// A publisher for properties used with the `@Published` attribute.
    public struct Publisher: SignalProtocol {
        public typealias Element = Value
        public typealias Error = Never
        
        fileprivate let subject: ReplayOneSubject<Value, Never>
        
        public func observe(with observer: @escaping (Signal<Value, Never>.Event) -> Void) -> Disposable {
            self.subject.observe(with: observer)
        }
        
        fileprivate init(_ output: Element) {
            self.subject = ReplayOneSubject<Value, Never>()
            self.subject.send(output)
        }
    }
    
    public var wrappedValue: Value {
        get { self.value }
        set {
            self.willChangeSubject.send()
            self.value = newValue
            self.publisher?.subject.send(newValue)
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

#endif
