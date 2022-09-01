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
public class ClippingAudioSource: IndexedAudioSource {
    let start: Int
    let end: Int

    init(from: Int, to: Int) {
        start = from
        end = to
    }
}
