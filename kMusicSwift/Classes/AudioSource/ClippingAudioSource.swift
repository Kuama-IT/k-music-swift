//
// ClippingAudioSource.swift
// kMusicSwift
// Created by Kuama Dev Team on 01/09/22
// Using Swift 5.0
// Running on macOS 12.5
//

/**
 An `AudioSource` that plays just part of itself
 */
public class ClippingAudioSource: AudioSource {
    public private(set) var realAudioSource: AudioSource

    let start: Int
    let end: Int

    public var playingStatus: AudioSourcePlayingStatus {
        realAudioSource.playingStatus
    }

    public var audioUrl: URL? {
        realAudioSource.audioUrl
    }

    public init(with singleAudioSource: AudioSource, from: Int, to: Int) {
        start = from
        end = to
        realAudioSource = singleAudioSource
    }

    public func setPlayingStatus(_ nextStatus: AudioSourcePlayingStatus) throws {
        try realAudioSource.setPlayingStatus(nextStatus)
    }
}
