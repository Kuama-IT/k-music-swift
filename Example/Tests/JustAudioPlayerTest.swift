//
//  JustAudioPlayerTest.swift
//  kMusicSwift_Tests
//
//  Created by Mac on 26/08/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import kMusicSwift
import XCTest

class JustAudioPlayerTest: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLocalAudioSource() throws {
        // A `LocalAudioSource` can be built with a string representing a path to the local filesystem
        let localAudio = LocalAudioSource(at: "sample.mp3")
        assert(localAudio.audioUrl == Bundle.main.url(forResource: "sample.mp3", withExtension: ""))
        assert(localAudio.playingStatus == .idle)
    }

    func testLocalAudioSourceCannotBuffer() throws {
        let localAudio = LocalAudioSource(at: "sample.mp3")

        XCTAssertThrowsError(try localAudio.setPlayingStatus(.buffering)) { error in
            XCTAssertEqual((error as! BadPlayingStatusError).value, .buffering)
        }
    }

    func testRemoteAudioSource() throws {
        // A `LocalAudioSource` can be built with a string representing a remote url
        let remoteAudio = RemoteAudioSource(at: "https://fake.url")
        assert(remoteAudio.audioUrl == URL(string: "https://fake.url")!)
        assert(remoteAudio.playingStatus == .idle)
    }

    func testRemoteAudioSourceCanBuffer() throws {
        let remoteAudio = RemoteAudioSource(at: "https://fake.url")
        XCTAssertNoThrow(try remoteAudio.setPlayingStatus(.buffering))

        assert(remoteAudio.playingStatus == .buffering)
    }

    func testIndexedAudioSourceMustBeBuildWithSingleAudioSource() throws {
        let localAudio = LocalAudioSource(at: "sample.mp3")
        let indexedAudioSource = IndexedAudioSequence(with: localAudio)
        assert(indexedAudioSource.playingStatus == localAudio.playingStatus)
        assert(indexedAudioSource.playbackOrder == [0])
        assert(indexedAudioSource.sequence[0].playingStatus == localAudio.playingStatus)
        assert(indexedAudioSource.sequence.count == 1)
    }

    func testIndexedAudioSourceShuffleDoesNothing() throws {
        let localAudio = LocalAudioSource(at: "sample.mp3")
        let indexedAudioSource = IndexedAudioSequence(with: localAudio)
        indexedAudioSource.playbackOrder = [3]
        assert(indexedAudioSource.playbackOrder == [0])
    }

    func testCannotSetPlayingStatusBeforeSettingCurrentTrack() throws {
        let localAudio = LocalAudioSource(at: "sample.mp3")
        let indexedAudioSource = IndexedAudioSequence(with: localAudio)
        XCTAssertThrowsError(try indexedAudioSource.setPlayingStatus(.playing)) { error in
            XCTAssertEqual((error as! InconsistentStateError).message, "Please set the current index before setting the playing status")
        }

        indexedAudioSource.currentSequenceIndex = 10
        assert(indexedAudioSource.currentSequenceIndex == 0)

        try indexedAudioSource.setPlayingStatus(.playing)

        assert(indexedAudioSource.playingStatus == .playing)
    }
}
