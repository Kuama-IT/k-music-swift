//
//  TrackResource.swift
//  kMusicSwift
//
//  Created by Mac on 26/08/22.
//

import AVFAudio
import SwiftAudioPlayer

public enum TrackResourcePlayingStatus {
    case playing
    case paused
    case buffering
    case ended
    case idle

    static func fromSAPlayingStatus(_ playingStatus: SAPlayingStatus) -> TrackResourcePlayingStatus {
        switch playingStatus {
        case .playing:
            return .playing
        case .paused:
            return .paused
        case .buffering:
            return .buffering
        case .ended:
            return .ended
        }
    }
}

// URLs
// Assets
// Files
// TO BE SUPPORTED Schemes: https | file: | asset:
public class TrackResource {
    public private(set) var audioUrl: URL?
    public private(set) var isRemote: Bool

    public private(set) var playingStatus: TrackResourcePlayingStatus = .idle

    public init(uri: String, isRemote: Bool = false) {
        audioUrl = isRemote ? URL(string: uri) : Bundle.main.url(forResource: uri, withExtension: "")
        self.isRemote = isRemote
    }

    /// Enforces the correct flow of the status of a track
    public func setPlayingStatus(_ nextStatus: TrackResourcePlayingStatus) {
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
