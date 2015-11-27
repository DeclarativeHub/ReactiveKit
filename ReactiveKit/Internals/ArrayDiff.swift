//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Srdan Rasic (@srdanrasic)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

// Created by Dapeng Gao on 20/10/15.
// The central idea of this algorithm is taken from https://github.com/jflinter/Dwifft

internal enum DiffStep<T> {
  case Insert(element: T, index: Int)
  case Delete(element: T, index: Int)
}

extension Array where Element: Equatable {

  internal static func diff(x: [Element], _ y: [Element]) -> [DiffStep<Element>] {

    if x.count == 0 {
      return zip(y, y.indices).map(DiffStep<Element>.Insert)
    }

    if y.count == 0 {
      return zip(x, x.indices).map(DiffStep<Element>.Delete)
    }

    // Use dynamic programming to generate a table such that `table[i][j]` represents
    // the length of the longest common substring (LCS) between `x[0..<i]` and `y[0..<j]`
    let xLen = x.count, yLen = y.count
    var table = [[Int]](count: xLen + 1, repeatedValue: [Int](count: yLen + 1, repeatedValue: 0))
    for i in 1...xLen {
      for j in 1...yLen {
        if x[i - 1] == y[j - 1] {
          table[i][j] = table[i - 1][j - 1] + 1
        } else {
          table[i][j] = max(table[i - 1][j], table[i][j - 1])
        }
      }
    }

    // Backtrack to find out the diff
    var backtrack: [DiffStep<Element>] = []
    for var i = xLen, j = yLen; i > 0 || j > 0; {
      if i == 0 {
        j--
        backtrack.append(.Insert(element: y[j], index: j))
      } else if j == 0 {
        i--
        backtrack.append(.Delete(element: x[i], index: i))
      } else if table[i][j] == table[i][j - 1] {
        j--
        backtrack.append(.Insert(element: y[j], index: j))
      } else if table[i][j] == table[i - 1][j] {
        i--
        backtrack.append(.Delete(element: x[i], index: i))
      } else {
        i--
        j--
      }
    }

    // Reverse the result
    return backtrack.reverse()
  }
}
