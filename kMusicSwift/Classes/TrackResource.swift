//
//  TrackResource.swift
//  kMusicSwift
//
//  Created by Mac on 26/08/22.
//

import AVFAudio
import SwiftAudioPlayer

// TODO: this should become somethin that extends a UriAudioSource
// URLs
// Assets
// Files
// TO BE SUPPORTED Schemes: https | file: | asset:
public class TrackResource {
    public private(set) var audioUrl: URL?
    public private(set) var isRemote: Bool

    public private(set) var playingStatus: AudioSourcePlayingStatus = .idle

    public init(uri: String, isRemote: Bool = false) {
        audioUrl = isRemote ? URL(string: uri) : Bundle.main.url(forResource: uri, withExtension: "")
        self.isRemote = isRemote
    }

    /// Enforces the correct flow of the status of a track
    public func setPlayingStatus(_ nextStatus: AudioSourcePlayingStatus) {
        switch playingStatus {
        case .playing:
            if nextStatus != .playing, nextStatus != .idle {
                playingStatus = nextStatus
            }
        case .paused:
            if nextStatus != .paused {
                playingStatus = nextStatus
            }
        case .buffering:
            if nextStatus != .ended {
                playingStatus = nextStatus
            }
        case .ended:
            if nextStatus != .idle {
                playingStatus = nextStatus
            }
        case .idle:
            if nextStatus != .ended, nextStatus != .paused {
                playingStatus = nextStatus
            }
        }
    }
}
