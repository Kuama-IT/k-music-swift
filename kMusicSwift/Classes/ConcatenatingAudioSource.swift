//
// ConcatenatingAudioSource.swift
// kMusicSwift
// Created by Kuama Dev Team on 01/09/22
// Using Swift 5.0
// Running on macOS 12.5
//

/**
 An `AudioSource` that holds a list of `IndexedAudioSource`, may represents a playlist of songs
 */
public class ConcatenatingAudioSource: AudioSource {
    public var sequence: [SingleAudioSource] = []

    public var playbackOrder: [Int] = []

    func concatenatingInsertAll(at _: Int, sources _: [AudioSource], shuffleIndexes _: [Int]) {}
    func concatenatingRemoveRange(from _: Int, to _: Int, shuffleIndexes _: [Int]) {}
}
