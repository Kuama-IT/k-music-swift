//
//  ViewController.swift
//  kMusicSwift
//
//  Created by cc18675dd6a3d8f9dd752f1bc3bc9210bda2938e on 08/26/2022.
//  Copyright (c) 2022 cc18675dd6a3d8f9dd752f1bc3bc9210bda2938e. All rights reserved.
//

import AVFoundation
import kMusicSwift
import UIKit

@available(iOS 15.0, *)
class ViewController: UIViewController {
    let jap = JustAudioPlayer()
    @IBOutlet var playOrPauseBtn: UIButton!
    @IBOutlet var stopBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            let builder = try TrackResourceBuilder()
                .fromAsset("AudioSource.mp3")
            let resource = try builder.build()
            jap.setTrack(resource)
        } catch JustAudioPlayerError.couldNotFindAsset {
            print("couldNotFindAsset")
        } catch JustAudioPlayerError.couldNotLoadUrlIntoTrackResource {
            print("couldNotLoadUrlIntoTrackResource")
        } catch {
            print(error.localizedDescription)
        }
    }

    @IBAction func onPlayOrPause(sender: UIButton) {
        if jap.isPlaying {
            jap.pause()
            sender.setTitle("Play", for: .normal)
        } else {
            jap.play()
            sender.setTitle("Pause", for: .normal)
        }
    }

    @IBAction func onStop(_: Any) {
        jap.stop()
        playOrPauseBtn.setTitle("Play", for: .normal)
        // TODO: reset the jap's queue tracks after stop, otherwise it will not work
    }
}
