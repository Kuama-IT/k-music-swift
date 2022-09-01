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
public class LoopingAudioSource: IndexedAudioSource {
    // The number of times this audio source should loop
    let count: Int

    init(with singleAudioSource:SingleAudioSource, count: Int) {
        self.count = count
        super.init(with: singleAudioSource)
    }
}
