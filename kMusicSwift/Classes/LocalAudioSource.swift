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
public class LocalAudioSource: IndexedAudioSource {
    public private(set) var audioUrl: URL?

    public init(at uri: String) {
        super.init()

        audioUrl = Bundle.main.url(forResource: uri, withExtension: "")
        sequence = [self]
        playbackOrder = [0]
    }
}
