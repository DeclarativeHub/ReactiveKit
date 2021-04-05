//
//  Future.swift
//  ReactiveKit
//
//  Created by Ibrahim Koteish on 05/04/2021.
//  Copyright © 2021 DeclarativeHub. All rights reserved.

import Foundation

/// A signal that eventually produces single value and then finishes or fails.
public final class Future<Element, Error: Swift.Error>: SignalProtocol {

  public typealias Promise = (Result<Element, Error>) -> Void

  private let subject = PassthroughSubject<Element, Error>()

  private let lock = NSLock()
  private var result: Result<Element, Error>?

  public init(_ attemptToFulfill: @escaping (@escaping Promise) -> Void) {
    attemptToFulfill(self.complete)
  }

  public func observe(with observer: @escaping Observer<Element, Error>) -> Disposable {
    self.lock.lock(); defer { self.lock.unlock() }

    if let result = self.result {
      return Signal<Element, Error>(result: result).observe(with: observer)
    }

    let disposable = self.subject.observe(with: observer)
    return disposable
  }

  private func complete(_ result: Result<Element, Error>) {

    self.lock.lock()
    guard self.result == nil else {
      self.lock.unlock()
      return
    }

    self.result = result
    self.lock.unlock()

    switch result {
    case let .success(output):
      self.subject.send(lastElement: output)
    case let .failure(error):
      self.subject.send(completion: .failure(error))
    }
  }
}
