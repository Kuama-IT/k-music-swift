//
// EqualizerTest.swift
// kMusicSwift_Tests
// Created by Kuama Dev Team on 08/09/22
// Using Swift 5.0
// Running on macOS 12.5
//

import kMusicSwift
import XCTest

class EqualizerTest: XCTestCase {
    let preSets: [PreSet] = [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [4, 6, 5, 0, 1, 3, 5, 4.5, 3.5, 0],
        [4, 3, 2, 2.5, -1.5, -1.5, 0, 1, 2, 3],
        [5, 4, 3.5, 3, 1, 0, 0, 0, 0, 0],
    ]

    let wrongPresets: [PreSet] = [[1.0]]

    func testItAllowsToUpdatePreSets() throws {
        let equalizer = try Equalizer()

        try equalizer.setPreSets(preSets)

        assert(equalizer.preSets == preSets)
    }

    func testItThrowsWhenBuiltWithWrongPreSets() throws {
        XCTAssertThrowsError(try Equalizer(preSets: wrongPresets)) { error in
            XCTAssertEqual((error as! WrongPreSetForFrequencesError).baseDescription, "Trying to provide an invalid preset \([1.0]) for frequencies \([32, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000])")
        }
    }

    func testItThrowsWhenUpdatingWithInvalidPresets() throws {
        let equalizer = try Equalizer()
        XCTAssertThrowsError(try equalizer.setPreSets(wrongPresets)) { error in
            XCTAssertEqual((error as! WrongPreSetForFrequencesError).baseDescription, "Trying to provide an invalid preset \([1.0]) for frequencies \([32, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000])")
        }
    }

    func testItCanActivateAPreset() throws {
        let equalizer = try Equalizer()

        try equalizer.setPreSets(preSets)

        try equalizer.activate(preset: 1)

        let preset = preSets[1]

        for i in 0 ... (equalizer.node.bands.count - 1) {
            assert(equalizer.node.bands[i].gain == preset[i])
        }

        assert(equalizer.activePreset == preset)
    }

    func testItCanDeactivateCurrentPreset() throws {
        let equalizer = try Equalizer()
        equalizer.resetGains()
        for i in 0 ... (equalizer.node.bands.count - 1) {
            assert(equalizer.node.bands[i].gain == 0)
        }
        assert(equalizer.activePreset == nil)
    }

    func testItAllowsToTweakAPreset() throws {
        let equalizer = try Equalizer()
        try equalizer.tweakBandGain(band: 1, gain: 10)
        assert(equalizer.node.bands[1].gain == 10)
        assert(equalizer.activePreset == nil)
    }

    func testItCheckThatTheBandIsCorrectBeforeTweakingTheValue() throws {
        let equalizer = try Equalizer()

        XCTAssertThrowsError(try equalizer.tweakBandGain(band: 100, gain: 10)) { error in
            XCTAssertEqual((error as! BandNotFoundError).baseDescription, "Trying to update a non existent band \(100). Current bands count \(equalizer.node.bands.count)")
        }
    }
}
