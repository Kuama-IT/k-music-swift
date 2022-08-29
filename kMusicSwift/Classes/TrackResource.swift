//
//  TrackResource.swift
//  kMusicSwift
//
//  Created by Mac on 26/08/22.
//

import AVFAudio

// URLs
// Assets
// Files
// TO BE SUPPORTED Schemes: https | file: | asset:
public struct TrackResource {
    var audioFile: AVAudioFile

    init(audioFile: AVAudioFile) {
        self.audioFile = audioFile
    }
}

/// Builds a TrackResource
public class TrackResourceBuilder {
    private var inputFileUrl: URL?

    public init(inputFileUrl: URL? = nil) {
        self.inputFileUrl = inputFileUrl
    }

    /// Expects an asset name with extension. Ex "track.mp3"
    @discardableResult
    public func fromAsset(_ asset: String) throws -> TrackResourceBuilder {
        guard let inputFileUrl = Bundle.main.url(forResource: asset, withExtension: "") else {
            throw CouldNotFindAssetError(message: "input file url: \(inputFileUrl?.description ?? "nil"), asset: \(asset)", cause: nil)
        }

        self.inputFileUrl = inputFileUrl

        return self
    }

    public func build() throws -> TrackResource {
        guard let inputFileUrl = inputFileUrl else {
            // TODO: this should become a "resource not provided to builder error" when all resource types are handled
            fatalError("Provide an asset via the fromAsset method")
        }

        // Load the track inside a AVAudioFile
        guard let inputFile = try? AVAudioFile(forReading: inputFileUrl) else {
            throw CouldNotLoadUrlIntoTrackResourceError(message: "input file url: \(inputFileUrl.description)", cause: nil)
        }

        return TrackResource(audioFile: inputFile)
    }
}
