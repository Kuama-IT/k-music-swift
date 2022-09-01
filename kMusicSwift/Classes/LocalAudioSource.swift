//
// LocalAudioSource.swift
// kMusicSwift
// Created by Kuama Dev Team on 01/09/22
// Using Swift 5.0
// Running on macOS 12.5
//

/**
 An `AudioSource` that holds an audio file stored inside the local filesystem
 It can be built with a string representing a full path to the audio file inside the local filesystem.
 */
public class LocalAudioSource: SingleAudioSource {
    public var playingStatus: AudioSourcePlayingStatus = .idle

    public private(set) var audioUrl: URL?

    public init(at uri: String) {
        audioUrl = Bundle.main.url(forResource: uri, withExtension: "")
    }

    public func setPlayingStatus(_ nextStatus: AudioSourcePlayingStatus) throws {
        if nextStatus == .buffering {
            throw BadPlayingStatusError(value: nextStatus)
        }
        switch playingStatus {
        case .playing:
            if nextStatus != .playing, nextStatus != .idle {
                playingStatus = nextStatus
            }
        case .paused:
            if nextStatus != .paused {
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
        default:
            throw BadPlayingStatusError(value: nextStatus)
        }
    }
}
