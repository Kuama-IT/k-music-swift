//
// ClippingAudioSequence.swift
// kMusicSwift
// Created by Kuama Dev Team on 01/09/22
// Using Swift 5.0
// Running on macOS 12.5
//

/**
 An `AudioSequence` that plays just part of itself
 */
public class ClippingAudioSequence: IndexedAudioSequence {
    let start: Int
    let end: Int

    init(with singleAudioSource: AudioSource, from: Int, to: Int) {
        start = from
        end = to
        super.init(with: singleAudioSource)
    }
}
