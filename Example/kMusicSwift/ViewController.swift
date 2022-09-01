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
    @IBOutlet var seekSlider: UISlider!
    @IBOutlet var volumeLabel: UILabel!
    @IBOutlet var seekLabel: UILabel!

    var cancellables: [AnyCancellable] = []
    override func viewDidLoad() {
        super.viewDidLoad()

        jap.$duration
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] duration in
                guard let self = self else { return }
                self.seekSlider.maximumValue = Float(duration)
            }).store(in: &cancellables)

        jap.$elapsedTime
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] elapsed in
                guard let self = self else { return }
                let rounded = RoundingHelper.preciseRound(elapsed, precision: .hundredths)
                self.seekLabel.text = "Time in seconds elapsed in seconds: \(rounded)"
                if !self.seekSlider.isTracking {
                    self.seekSlider.value = Float(elapsed)
                }

            }).store(in: &cancellables)

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
            .sink(receiveValue: { [weak self] volume in
                guard let self = self else { return }
                self.volumeSlider.value = volume
                let rounded = RoundingHelper.preciseRound(Double(volume), precision: .hundredths) * 10.0
                self.volumeLabel.text = "Volume: \(rounded)/10"

            }).store(in: &cancellables)

        let remote = RemoteAudioSource(at: "https://s3-us-west-2.amazonaws.com/s.cdpn.io/123941/Yodel_Sound_Effect.mp3")

        let local = LocalAudioSource(at: "nature.mp3")

        let remote2 = RemoteAudioSource(at: "https://ribgame.com/remote.mp3")

        jap.addAudioSource(ConcatenatingAudioSequence(with: [remote, local, remote2]))
        do {
            try jap.setVolume(0.1)
        } catch {
            handleError(error: error)
        }
    }

    @IBAction func onPlayOrPause(sender: UIButton) {
        do {
            if jap.isPlaying {
                jap.pause()
                sender.setTitle("▶️", for: .normal)
            } else {
                try jap.play()
                sender.setTitle("⏸", for: .normal)
            }
        } catch {
            handleError(error: error)
        }
    }

    @IBAction func onNext(_: Any) {
        do {
            try jap.seekToNext()
        } catch {
            handleError(error: error)
        }
    }

    @IBAction func onPrevious(_: Any) {
        do {
            try jap.seekToPrevious()
        } catch {
            handleError(error: error)
        }
    }

    @IBAction func onLoopMode(_: Any) {
        jap.setNextLoopMode()
    }

    @IBAction func onStop(_: Any) {
        jap.stop()
        playOrPauseBtn.setTitle("▶️", for: .normal)
        // TODO: reset the jap's queue tracks after stop, otherwise it will not work
    }

    @IBAction func onSeekChanged(_ sender: UISlider) {
        if !sender.isTracking {
            jap.seek(second: Double(sender.value))
        }
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
