//
//  BeatDetector.swift
//  beatdetector
//
//  Created by m on 18/07/2017.
//  Copyright © 2017 m. All rights reserved.
//

import Foundation

class BeatDetector {
  let ref: BeatDetectorRef
  init?(buffer: UnsafeBufferPointer<Float>) {
    var ref: BeatDetectorRef = .init()
    guard let data = buffer.baseAddress else { return nil }
    BeatDetectorNew(data, UInt32(buffer.count), &ref)
    self.ref = ref
  }
  var beat: UnsafePointer<Float> {
    return .init(BeatDetectorGetBeat(ref))
  }
  var tempo: Int {
    return Int(BeatDetectorGetTempo(ref))
  }
  deinit {
    BeatDetectorDelete(ref)
  }
}

extension Data {
  func beatDetector() -> BeatDetector? {
    return withUnsafeBytes { bytes in
      BeatDetector(buffer: UnsafeBufferPointer<Float>(start: bytes, count: count / MemoryLayout<Float>.size))
    }
  }
}

