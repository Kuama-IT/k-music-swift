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
}
