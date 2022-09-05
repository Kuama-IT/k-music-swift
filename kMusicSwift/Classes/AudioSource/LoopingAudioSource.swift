//
// LoopingAudioSource.swift
// kMusicSwift
// Created by Kuama Dev Team on 01/09/22
// Using Swift 5.0
// Running on macOS 12.5
//

/**
 An `AudioSource` that loops for N times before being considered "finished"
 */
public class LoopingAudioSource: AudioSource {
    // The number of times this audio source should loop
    let count: Int

    private var realAudioSource: AudioSource

    public var playingStatus: AudioSourcePlayingStatus {
        realAudioSource.playingStatus
    }

    public var audioUrl: URL? {
        realAudioSource.audioUrl
    }

    public init(with singleAudioSource: AudioSource, count: Int) {
        self.count = count
        realAudioSource = singleAudioSource
    }

    public func setPlayingStatus(_ nextStatus: AudioSourcePlayingStatus) throws {
        try realAudioSource.setPlayingStatus(nextStatus)
    }
}
