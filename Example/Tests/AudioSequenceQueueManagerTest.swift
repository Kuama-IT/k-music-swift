//
// AudioSequenceQueueManagerTest.swift
// kMusicSwift_Tests
// Created by Kuama Dev Team on 02/09/22
// Using Swift 5.0
// Running on macOS 12.5
//

import kMusicSwift
import XCTest

class AudioSequenceQueueManagerTest: XCTestCase {
    func testItCanAddAndRemoveAudioSources() throws {
        let queueManager = AudioSequenceQueueManager()

        let localAudio = LocalAudioSource(at: "sample.mp3")
        let remoteAudio = RemoteAudioSource(at: "http://in.web/sample.mp3")

        queueManager.addAll(sources: [IndexedAudioSequence(with: localAudio)])

        assert(queueManager.count == 1)

        let otherAudioSources: [AudioSequence] = [
            ConcatenatingAudioSequence(with: [localAudio, remoteAudio]),
            IndexedAudioSequence(with: localAudio),
        ]

        queueManager.addAll(sources: otherAudioSources)
        assert(queueManager.count == 4)

        try queueManager.remove(at: 3)

        assert(queueManager.count == 3)
    }

    func testItAllowsToForceClearTheQueue() {
        let queueManager = AudioSequenceQueueManager()
        let localAudio = LocalAudioSource(at: "sample.mp3")

        queueManager.addAll(sources: [IndexedAudioSequence(with: localAudio)])

        queueManager.clear()

        assert(queueManager.count == 0)
    }

    func testItPreventsFromRemovingAudioSourcesThatArePlaying() throws {
        let queueManager = AudioSequenceQueueManager()

        let localAudio = LocalAudioSource(at: "sample.mp3")
        let remoteAudio = RemoteAudioSource(at: "http://in.web/sample.mp3")

        try remoteAudio.setPlayingStatus(.buffering)

        let otherAudioSources: [AudioSequence] = [
            ConcatenatingAudioSequence(with: [localAudio, remoteAudio]),
            IndexedAudioSequence(with: localAudio),
        ]

        queueManager.addAll(sources: otherAudioSources)

        XCTAssertThrowsError(try queueManager.remove(at: 1)) { error in
            XCTAssertEqual((error as! CannotRemoveAudioSourceFromSequenceError).currentStatus, .buffering)
        }
    }

    func testItThrowsCustomErrorIfRemoveIndexIsOutOfBounds() throws {
        let queueManager = AudioSequenceQueueManager()

        XCTAssertThrowsError(try queueManager.remove(at: 1)) { error in
            XCTAssertEqual((error as! QueueIndexOutOfBoundError).count, 0)
        }
    }

    func testItAllowsToAccessToAudioSourceWithoutKnowingAboutNesting() throws {
        let queueManager = AudioSequenceQueueManager()

        let localAudio = LocalAudioSource(at: "sample.mp3")
        let remoteAudio = RemoteAudioSource(at: "http://in.web/sample.mp3")
        queueManager.addAll(sources: [
            IndexedAudioSequence(with: localAudio),
            ConcatenatingAudioSequence(with: [localAudio, remoteAudio]),
            LoopingAudioSequence(with: localAudio, count: 3),
        ])

        let element = try queueManager.element(at: 2)

        assert(element.audioUrl == remoteAudio.audioUrl)
    }
    
    func testItAllowsToShuffleItsSequences() throws {
        let queueManager = AudioSequenceQueueManager()
        let localSources = (0...4).map { RemoteAudioSource(at: "sample-\($0).mp3")}
        
        queueManager.addAll(sources: [ConcatenatingAudioSequence(with: localSources)])
        try queueManager.shuffle(at: 0, inOrder: [4, 3, 2, 1, 0])
        
        let source = try queueManager.element(at: 0)
        
        assert(source.audioUrl == localSources[4].audioUrl)
        
    }
}
