//
// AudioSource.swift
// kMusicSwift
// Created by Kuama Dev Team on 01/09/22
// Using Swift 5.0
// Running on macOS 12.5
//

/**
 Base class to represent an audio file wrapper
 All audio file wrapper must have at least one audio source, and allow to set a shuffle order
 */
public protocol AudioSource {
    /// The list of audios that this AudioSource contains
    var sequence: [SingleAudioSource] { get set }

    /**
     The order in which the `sequence` should be played.
     A shuffle action would change this array
     */
    var playbackOrder: [Int] { get set }
}
