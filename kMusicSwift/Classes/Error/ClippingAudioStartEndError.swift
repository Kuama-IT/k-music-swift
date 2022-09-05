//
//  ClippingAudioStartEndError.swift
//  kMusicSwift
//
//  Created by kuama on 05/09/22.
//

import Foundation

public class ClippingAudioStartEndError: JustAudioPlayerError {
    override public var baseDescription: String {
        "End must be greater than start"
    }
}
