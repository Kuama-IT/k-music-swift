//
// AudioSequenceQueueManager.swift
// kMusicSwift
// Created by Kuama Dev Team on 02/09/22
// Using Swift 5.0
// Running on macOS 12.5
//

/**
 Manages the order in which a queue of `AudioSequence` should be reproduced
 */
public class AudioSequenceQueueManager {
    private var queue: [AudioSequence] = []

    public var count: Int {
        return queue.reduce(0) { partialResult, sequence in
            partialResult + sequence.sequence.count
        }
    }

    public var first: AudioSource? {
        // TODO: this should take in account the shuffle order
        if queue.count > 0 {
            return queue[0].sequence.first
        }

        return nil
    }

    public init() {}

    // TODO: this should take in account the shuffle order
    public func element(at index: Int) throws -> AudioSource {
        var mutableIndex = index
        var audioSequenceIndex = 0
        var found = false
        var audioSource: AudioSource?
        while !found {
            if !queue.indices.contains(audioSequenceIndex) {
                throw QueueIndexOutOfBoundError(index: index, count: count)
            }

            let audioSequence = queue[audioSequenceIndex]
            if audioSequence.sequence.indices.contains(mutableIndex) {
                audioSource = audioSequence.sequence[mutableIndex]
                found = true
            } else {
                audioSequenceIndex += 1
                mutableIndex -= audioSequence.sequence.count
            }
        }

        guard let audioSource = audioSource else {
            throw QueueIndexOutOfBoundError(index: index, count: count)
        }

        return audioSource
    }

    public func contains(_ index: Int) -> Bool {
        do {
            _ = try element(at: index)
            return true
        } catch {
            return false
        }
    }

    public func addAll(sources: [AudioSequence]) {
        queue.append(contentsOf: sources)
    }

    public func clear() {
        queue.removeAll()
    }

    public func remove(at index: Int) throws {
        var mutableIndex = index
        var audioSequenceIndex = 0
        var removed = false
        while !removed {
            if !queue.indices.contains(audioSequenceIndex) {
                throw QueueIndexOutOfBoundError(index: index, count: count)
            }

            var audioSequence = queue[audioSequenceIndex]
            if audioSequence.sequence.indices.contains(mutableIndex) {
                let audioSource = audioSequence.sequence[mutableIndex]

                if audioSource.playingStatus == .playing || audioSource.playingStatus == .buffering {
                    throw CannotRemoveAudioSourceFromSequenceError(currentStatus: audioSource.playingStatus)
                }

                audioSequence.sequence.remove(at: mutableIndex)
                removed = true
            } else {
                audioSequenceIndex += 1
                mutableIndex -= audioSequence.sequence.count
            }
        }
    }
}
