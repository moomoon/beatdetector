//
//  AudioDecoder.swift
//  beatdetector
//
//  Created by m on 18/07/2017.
//  Copyright © 2017 m. All rights reserved.
//

import Foundation

import AVFoundation
import Runes
import RxSwift
//import AudioKit

extension Data {
  mutating func append(audioBuffersFrom sampleBuffer: CMSampleBuffer, at offset: Int) throws -> Int {
    guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return 0 }
    let dataLength = CMBlockBufferGetDataLength(blockBuffer)
    try self.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) -> () in
      let result = CMBlockBufferCopyDataBytes(blockBuffer, 0, dataLength, bytes.advanced(by: offset))
      if result != 0 { throw AudioDecoderError.copyBufferError(result) }
    }
    return dataLength
  }
}

private struct AVAssetReaderOutputSequence: Sequence, IteratorProtocol {
  typealias Element = CMSampleBuffer
  typealias Iterator = AVAssetReaderOutputSequence
  let output: AVAssetReaderOutput
  let queue: DispatchQueue
  func makeIterator() -> AVAssetReaderOutputSequence {

    return self
  }
  mutating func next() -> CMSampleBuffer? {
    return output.copyNextSampleBuffer(timeout: 20, in: queue)
  }
}

extension AVAssetReaderOutput {
  func sequence(on queue: DispatchQueue = .init(label: "AVAssetReaderAudioMixOutputQueue")) -> AnySequence<CMSampleBuffer> {
    return .init(AVAssetReaderOutputSequence(output: self, queue: queue))
  }

  func data(size: Int, isCancelled: @escaping () -> Bool) throws -> Data? {
    var data: Data = .init(count: size)
    var offset = 0
    for buffer in sequence() {
      if isCancelled() { return nil }
      #if DEBUG
        offset += try data.append(audioBuffersFrom: buffer, at: offset)
      #else
        if let length = try? data.append(audioBuffersFrom: buffer, at: offset) {
          offset += length
        }
      #endif
    }
    offset ->> logger("got data")
    return isCancelled() ? nil : data
  }
}

enum LocalAssetBGM {
  case asset(AVAsset), mix(AVComposition, AVAudioMix)
}

extension LocalAssetBGM {
  var asset: AVAsset {
    switch self {
    case let .asset(asset): return asset
    case let .mix(composition, _): return composition
    }
  }
}

extension AVAsset {
  var audioDuration: CMTime? {
    return tracks(withMediaType: AVMediaTypeAudio).first?.timeRange.end
  }
}

enum AudioSamplePolicy {
  case perSecond(Int), max(Int)
}

extension AudioSamplePolicy {
  static var ezAudioCompatible: AudioSamplePolicy {
    //    return .perSecond(.init(EZAudioPlotDefaultMaxHistoryBufferLength))
    return .perSecond(8096)

  }
}

extension LocalAssetBGM {
  func asObservable() -> Observable<Data> {
    return Observable.create { observer in
      let start = Date.timeIntervalSinceReferenceDate
      let decodeStart = start
      defer { print("----------- decoding and sampling audio used \(Date.timeIntervalSinceReferenceDate - start)") }
      let audioSettings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM,
                                          AVLinearPCMBitDepthKey: 32,
                                          AVSampleRateKey: 44100,
                                          AVLinearPCMIsBigEndianKey: false,
                                          AVLinearPCMIsFloatKey: true,
                                          AVNumberOfChannelsKey: 1]
      let reader: AVAssetReader, output: AVAssetReaderOutput
      switch self {
      case let .asset(asset):
        reader = try .init(asset: asset)
        guard let audioTrack = asset.tracks(withMediaType: AVMediaTypeAudio).first else { throw AudioDecoderError.noAudioTrack }
        output = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: audioSettings)
      case let .mix(asset, mix):
        reader = try .init(asset: asset)
        let audioMixOutput = AVAssetReaderAudioMixOutput(audioTracks: asset.tracks(withMediaType: AVMediaTypeAudio), audioSettings: audioSettings)
        audioMixOutput.audioMix = mix
        output = audioMixOutput
      }
      reader.add(output)
      reader.startReading()
      let disposable: CompositeDisposable = .init()
      do {
        guard let data = try output.data(size: Int(ceil(Double(44100 * 4) * self.asset.duration.seconds)) ->> logger("size"), isCancelled: { disposable.isDisposed }) else { return disposable }
        observer.onNext(data)
        observer.onCompleted()
//        try data.write(to: URL.init(fileURLWithPath: "\(NSTemporaryDirectory())temp") ->> logger("temp url")) ->> logger("written to")
      } catch let e {
        observer.onError(e)
      }

      return disposable
    }
  }
}


//extension ObservableType where E == (UnsafeMutablePointer<Float>, UInt32) {
//  func bindTo(_ plot: EZPlot) -> Disposable {
//    return bindNext {
//      plot.updateBuffer($0, withBufferSize: $1)
//      $0.deallocate(capacity: .init($1))
//    }
//  }
//}

enum AudioDecoderError: Error {
  case noAudioTrack, copyBufferError(OSStatus)
}


extension AVAssetReaderOutput {
  func copyNextSampleBuffer(timeout time: TimeInterval, in queue: DispatchQueue) -> CMSampleBuffer? {
    return queue.timeout(time) { [weak self] in self?.copyNextSampleBuffer() }
  }
}
