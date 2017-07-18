//
//  DispatchQueueExtensions.swift
//  beatdetector
//
//  Created by m on 19/07/2017.
//  Copyright © 2017 m. All rights reserved.
//

import Foundation

extension DispatchQueue {
  func timeout<A>(_ time: TimeInterval, value: @escaping () -> A?) -> A? {
    let group = DispatchGroup()
    var result: A?
    group.enter()
    async {
      result = value()
      group.leave()
    }
    _ = group.wait(timeout: .now() + time)
    return result
  }
}
