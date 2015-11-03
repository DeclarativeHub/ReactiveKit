//
//  TokenizedCollection.swift
//  rStreams
//
//  Created by Srdan Rasic on 02/11/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

public class TokenizedCollection<T> {
  public typealias Token = Int64
  
  private var storage: [Token:T] = [:]
  private var nextToken: Token = 0
  private let lock = RecursiveLock(name: "com.ReactiveKit.rStreams.TokenizedCollection")

  public init() {}
  
  public func insert(element: T) -> DisposableType {
    lock.lock()
    let token = nextToken
    nextToken = nextToken + 1
    lock.unlock()
    
    storage[token] = element
    
    return BlockDisposable { [weak self] in
      self?.storage.removeValueForKey(token)
    }
  }
  
  public func forEach(body: T -> ()) {
    return storage.values.forEach(body)
  }
}
