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
    private lazy var engine = AVAudioEngine()
    private lazy var jap = JustAudioPlayer(engine: engine)
    private lazy var jap2 = JustAudioPlayer(engine: engine)
    @IBOutlet var playOrPauseBtn: UIButton!
    @IBOutlet var stopBtn: UIButton!
    @IBOutlet var loopModeBtn: UIButton!
    @IBOutlet var nextBtn: UIButton!
    @IBOutlet var volumeSlider: UISlider!
    @IBOutlet var seekSlider: UISlider!
    @IBOutlet var volumeLabel: UILabel!
    @IBOutlet var speedLabel: UILabel!
    @IBOutlet var speedSlider: UISlider!
    @IBOutlet var seekLabel: UILabel!

    var cancellables: [AnyCancellable] = []
    override func viewDidLoad() {
        super.viewDidLoad()

        jap.$speed
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] speed in
                guard let self = self else { return }
                self.speedSlider.value = speed
                let rounded = RoundingHelper.preciseRound(Double(speed), precision: .ones)
                self.speedLabel.text = "Speed: \(rounded)/10"
            }).store(in: &cancellables)

        jap.$duration
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] duration in
                guard let self = self else { return }
                self.seekSlider.minimumValue = 0.0
                self.seekSlider.maximumValue = Float(duration)
            }).store(in: &cancellables)

        jap.$queueIndex
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { index in
                print("Reproducing \(index) song")
            }.store(in: &cancellables)

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
                    self.loopModeBtn.setTitle("????", for: .normal)
                case .one:
                    self.loopModeBtn.setTitle("????", for: .normal)
                case .all:
                    self.loopModeBtn.setTitle("????", for: .normal)
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

        jap.isShuffling
            .compactMap { $0 }.receive(on: DispatchQueue.main)
            .sink { print("\($0)") }
            .store(in: &cancellables)

        jap.$isPlaying
            .compactMap { $0 }
            .map { $0 ? "???" : "??????" }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {
                self.playOrPauseBtn.setTitle($0, for: .normal)
            })
            .store(in: &cancellables)

        jap.$outputWriteError
            .compactMap { $0 }.receive(on: DispatchQueue.main)
            .sink { print("\($0)") }
            .store(in: &cancellables)

        jap.$outputAbsolutePath
            .compactMap { $0 }.receive(on: DispatchQueue.main)
            .sink { print("\($0)") }
            .store(in: &cancellables)

        _ = RemoteAudioSource(at: "https://s3-us-west-2.amazonaws.com/s.cdpn.io/123941/Yodel_Sound_Effect.mp3")

        let local2 = LocalAudioSource(at: "nature.mp3")
        _ = LoopingAudioSource(with: local2, count: 5)
        let delay = DelayAudioEffect()

//        delay.setWetDryMix(90)
        delay.setBypass(false)
        delay.setDelayTime(1.0)
        delay.setFeedback(80)

        let reverb = ReverbAudioEffect()
        reverb.setBypass(false)
//        reverb.setPreset(.smallRoom)
        reverb.setWetDryMix(300)

        let distortion = DistortionAudioEffect()
        distortion.setBypass(false)
        distortion.setWetDryMix(40)

        let remote = RemoteAudioSource(at: "https://www.fesliyanstudios.com/musicfiles/2019-04-23_-_Trusted_Advertising_-" +
            "_www.fesliyanstudios.com/15SecVersion2019-04-23_-_Trusted_Advertising_-_www.fesliyanstudios.com.mp3",
            effects: [])
//        let local = LocalAudioSource(at: "AudioSource.mp3", effects: [delay])
//        let local = LocalAudioSource(at: "AudioSource.mp3", effects: [reverb])
        let shakerando = LocalAudioSource(at: "shakerando.mp3")
//        let local = LocalAudioSource(at: "AudioSource.mp3", effects: [distortion])
        let local = LocalAudioSource(at: "AudioSource.mp3", effects: [])
        do {
            let eq = try Equalizer(preSets: [
                [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                [4, 6, 5, 0, 1, 3, 5, 4.5, 3.5, 0],
                [4, 3, 2, 2.5, -1.5, -1.5, 0, 1, 2, 3],
                [5, 4, 3.5, 3, 1, 0, 0, 0, 0, 0],
            ])
            try jap.setEqualizer(eq)
            _ = try ClippingAudioSource(with: local, from: 10.0, to: 15.0)

            try jap.writeOutputToFile()

            jap.addAudioSource(IndexedAudioSequence(with: remote))
            try jap.setVolume(0.1)
            jap.setLoopMode(.off)
            try jap.play()

            jap2.addAudioSource(IndexedAudioSequence(with: shakerando))
            try jap2.setVolume(0.2)
            try jap2.play()

        } catch {
            handleError(error: error)
        }

        jap2Streams()
    }

    private func jap2Streams() {
        jap2.$speed
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {
                print("\($0) JAP2 SPEED")
            }).store(in: &cancellables)

        jap2.$duration
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {
                print("\($0) JAP2 DURATION")
            }).store(in: &cancellables)

        jap2.$queueIndex
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {
                print("\($0) JAP2 QUEUE INDEX")
            }).store(in: &cancellables)

        jap2.$elapsedTime
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {
                print("\($0) JAP2 ELAPSED TIME")
//                if $0 > 5{
//                    self.jap2.pause()
//                }
            }).store(in: &cancellables)

        jap2.$loopMode
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {
                print("\($0) JAP2 LOOP MODE")
            }).store(in: &cancellables)

        jap2.$volume
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {
                print("\($0) JAP2 VOLUME")
            }).store(in: &cancellables)

        jap2.isShuffling
            .compactMap { $0 }.receive(on: DispatchQueue.main)
            .sink(receiveValue: {
                print("\($0) JAP2 IS SHUFFLING")
            }).store(in: &cancellables)

        jap2.$isPlaying
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {
                print("\($0) JAP2 IS PLAYING")
            }).store(in: &cancellables)

        jap2.$outputWriteError
            .compactMap { $0 }.receive(on: DispatchQueue.main)
            .sink(receiveValue: {
                print("\($0) JAP2 OUTPUT WRITE ERROR")
            }).store(in: &cancellables)

        jap2.$outputAbsolutePath
            .compactMap { $0 }.receive(on: DispatchQueue.main)
            .sink(receiveValue: {
                print("\($0) JAP2 ABSOLUTE PATH")
            }).store(in: &cancellables)
    }

    @IBAction func onPlayOrPause(sender _: UIButton) {
        do {
            if jap.isPlaying {
                jap.pause()
            } else {
                try jap.play()
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
        // TODO: reset the jap's queue tracks after stop, otherwise it will not work
    }

    @IBAction func onSeekChanged(_ sender: UISlider) {
        if !sender.isTracking {
            jap.seek(second: Double(sender.value))
        }
    }

    @IBAction func onSpeedChanged(_ sender: UISlider) {
        do {
            try jap.setSpeed(sender.value)
        } catch {
            handleError(error: error)
        }
    }

    @IBAction func onVolumeChanged(_ sender: UISlider) {
        do {
            try jap.setVolume(sender.value)
        } catch {
            handleError(error: error)
        }
    }

    @IBAction func onEqualizeStatusChange(_ sender: UISwitch) {
        do {
            if sender.isOn {
                try jap.activateEqualizerPreset(at: 1)
            } else {
                try jap.resetGains()
            }
        } catch {
            handleError(error: error)
        }
    }

    @IBAction func onBandValueChange(_ sender: UISlider) {
        do {
            try jap.tweakEqualizerBandGain(band: 1, gain: sender.value * 10)
            try jap.tweakEqualizerBandGain(band: 3, gain: sender.value * 10)
            try jap.tweakEqualizerBandGain(band: 5, gain: sender.value * 10)
            try jap.tweakEqualizerBandGain(band: 7, gain: sender.value * 10)
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
