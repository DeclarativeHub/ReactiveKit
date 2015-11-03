//
//  Lock.swift
//  Streams
//
//  Created by Srdan Rasic on 18/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

import Foundation

internal class RecursiveLock: NSRecursiveLock {
  init(name: String) {
    super.init()
    self.name = name
  }
}
