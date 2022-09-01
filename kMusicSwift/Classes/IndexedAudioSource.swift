//
// IndexedAudioSource.swift
// kMusicSwift
// Created by Kuama Dev Team on 01/09/22
// Using Swift 5.0
// Running on macOS 12.5
//

/**
 An `AudioSource` that can appear in a sequence. Represents a single audio file (naming is inherited from `just_audio` plugin)
 */
public class IndexedAudioSource: AudioSource, SingleAudioSource {
    public var playbackOrder: [Int] {
        set {
            // no op
        }
        
        get {
            return [0]
        }
    }

    public var sequence: [SingleAudioSource] = []
    
    public init(with singleAudioSource:SingleAudioSource) {
        sequence = [singleAudioSource]
        playbackOrder = [0]
    }

    public var playingStatus: AudioSourcePlayingStatus {
        return sequence[playbackOrder.first!].playingStatus
    }

    public func setPlayingStatus(_ nextStatus: AudioSourcePlayingStatus) throws {
        return try sequence[playbackOrder.first!].setPlayingStatus(nextStatus)
    }
}
