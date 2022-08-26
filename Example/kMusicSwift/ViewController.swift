//
//  ViewController.swift
//  kMusicSwift
//
//  Created by cc18675dd6a3d8f9dd752f1bc3bc9210bda2938e on 08/26/2022.
//  Copyright (c) 2022 cc18675dd6a3d8f9dd752f1bc3bc9210bda2938e. All rights reserved.
//

import AVFAudio
import kMusicSwift
import UIKit

@available(iOS 15.0, *)
class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let a = JustAudioPlayer.init()
        a.play(trackPath: "nature")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
