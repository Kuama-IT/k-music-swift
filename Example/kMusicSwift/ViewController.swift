//
//  ViewController.swift
//  kMusicSwift
//
//  Created by cc18675dd6a3d8f9dd752f1bc3bc9210bda2938e on 08/26/2022.
//  Copyright (c) 2022 cc18675dd6a3d8f9dd752f1bc3bc9210bda2938e. All rights reserved.
//

import AVFoundation
import Combine
import kMusicSwift
import UIKit

@available(iOS 15.0, *)
class ViewController: UIViewController {
    private lazy var jap = JustAudioPlayer()
    @IBOutlet var playOrPauseBtn: UIButton!
    @IBOutlet var stopBtn: UIButton!
    @IBOutlet var loopModeBtn: UIButton!
    @IBOutlet var nextBtn: UIButton!
    @IBOutlet var volumeSlider: UISlider!

    var cancellables: [AnyCancellable] = []
    override func viewDidLoad() {
        super.viewDidLoad()

        jap.$loopMode
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {
                switch $0 {
                case .off:
                    self.loopModeBtn.setTitle("📴", for: .normal)
                case .one:
                    self.loopModeBtn.setTitle("🔂", for: .normal)
                case .all:
                    self.loopModeBtn.setTitle("🔁", for: .normal)
                }
            }).store(in: &cancellables)

        jap.$volume
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .assign(to: \.value, on: volumeSlider)
            .store(in: &cancellables)

        jap.addTrack(TrackResource(uri: "https://s3-us-west-2.amazonaws.com/s.cdpn.io/123941/Yodel_Sound_Effect.mp3", isRemote: true))
        jap.addTrack(TrackResource(uri: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3", isRemote: true))
        ["nature.mp3", "AudioSource.mp3"].forEach { track in
            jap.addTrack(TrackResource(uri: track))
        }
    }

    @IBAction func onPlayOrPause(sender: UIButton) {
        if jap.isPlaying {
            jap.pause()
            sender.setTitle("▶️", for: .normal)
        } else {
            jap.play()
            sender.setTitle("⏸", for: .normal)
        }
    }

    @IBAction func onNext(_: Any) {
        jap.seekToNext()
    }

    @IBAction func onLoopMode(_: Any) {
        jap.setNextLoopMode()
    }

    @IBAction func onStop(_: Any) {
        jap.stop()
        playOrPauseBtn.setTitle("▶️", for: .normal)
        // TODO: reset the jap's queue tracks after stop, otherwise it will not work
    }

    @IBAction func onVolumeChanged(_ sender: UISlider) {
        do {
            try jap.setVolume(sender.value)
        } catch {
            handleError(error: error)
        }
    }

    func handleError(error: Error) {
        if let error = error as? BaseError {
            print(error.description)
        } else {
            print(error.localizedDescription)
        }
    }
}
