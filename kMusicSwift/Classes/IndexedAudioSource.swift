//
// IndexedAudioSource.swift
// kMusicSwift
// Created by Kuama Dev Team on 01/09/22
// Using Swift 5.0
// Running on macOS 12.5
//

/**
 An `AudioSource` that can appear in a sequence. Represents a single audio file
 */
public class IndexedAudioSource: AudioSource, SingleAudioSource {
    public var playbackOrder: [Int] = []

    public var sequence: [SingleAudioSource] = []

    public var playingStatus: AudioSourcePlayingStatus {
        return sequence[playbackOrder.first!].playingStatus
    }

    /// Enforces the correct flow of the status of a track
    public func setPlayingStatus(_ nextStatus: AudioSourcePlayingStatus) throws {
        return try sequence[playbackOrder.first!].setPlayingStatus(nextStatus)
    }
}
