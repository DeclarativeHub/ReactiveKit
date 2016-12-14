//
//  Reactive.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 14/12/2016.
//  Copyright © 2016 Srdan Rasic. All rights reserved.
//

import Foundation

public protocol ReactiveExtensions {
  associatedtype Base
  var base: Base { get }
}

public struct Reactive<Base>: ReactiveExtensions {
  public let base: Base

  public init(_ base: Base) {
    self.base = base
  }
}

public protocol ReactiveExtensionsProvider: class {}

public extension ReactiveExtensionsProvider {

  public var reactive: Reactive<Self> {
    return Reactive(self)
  }

  public static var reactive: Reactive<Self>.Type {
    return Reactive<Self>.self
  }
}
