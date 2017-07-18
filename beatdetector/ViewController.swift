//
//  ViewController.swift
//  beatdetector
//
//  Created by m on 18/07/2017.
//  Copyright © 2017 m. All rights reserved.
//

import UIKit
import RxSwift
import AVFoundation

class ViewController: UIViewController {
  let bag = DisposeBag()
  let url = Bundle.main.url(forResource: "2067155_11121628_l", withExtension: "mp3")!
  lazy var player: AVPlayer = AVPlayer(url: self.url)
  var timeObserver: Any!
  var beat = false {
    willSet {
      guard newValue != beat else { return }
      view.backgroundColor = newValue ? .white : .black
    }
  }
  var beatDetector: BeatDetector! {
    didSet {
      player.play()
      self.timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.005, preferredTimescale: 44100), queue: .main) { [weak self] time in
        guard let beat = self?.beatDetector.beat.advanced(by: Int(time.seconds * 44100 / 1024)).pointee else { return }
        self?.beat = beat == 1
//        self.beatInt(time.seconds * 44100 * 4 / 1024)
      }
    }
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    LocalAssetBGM.asset(AVAsset(url: url)).asObservable().map {
      time("beatDetector") <<- $0.beatDetector()

      }.subscribe(onNext: { [weak self] beatDetector in
        self?.beatDetector = beatDetector
        beatDetector?.tempo ->> logger("tempo")
        return
      }).addDisposableTo(bag)
    // Do any additional setup after loading the view, typically from a nib.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

