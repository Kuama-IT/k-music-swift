import AVFoundation
import Darwin
import Foundation

// Icy Metadata (?)
// Volume ✅
// Composite state (?)
// Loop modes ✅
// Request headers ✅
// Concatenating ✅
// Gapless transitions ✅
// HLS (?)
// Radio/Livestreams ✅
// Time stretching (1x, 2x) ✅
// Buffer position (on download from http) ✅
// Shuffling ✅
// Clipping ✅
// Playlist editing ✅
// Audio effects
// Multiple tracks in one time
// Audio effects on a per-track basis
// Mixer
// Mixer presets
// Mixed output to file (or stream?)

public enum LoopMode {
    case off
    case one
    case all
}

@available(iOS 15.0, *)
public class JustAudioPlayer {
    public var isPlaying: Bool {
        playerNode.isPlaying
    }

    private let engine: AVAudioEngine = .init()
    private let playerNode: AVAudioPlayerNode = .init()

    // To be forwarded to the http client, in case we load a track from the internet
    var httpHeaders: [String: String] = [:]

    private var queue: [TrackResource] = []

    public init() {}

    /// To be modified in order to handle multiple tracks at once
    public func setTrack(_ track: TrackResource) {
        queue.append(track)
    }

    public func setAudioSource(_: AudioSource) {}

    // Play without waiting for completion
    // Play while waiting for completion
    public func play() {
        // TODO: ensure we have something in queue or return
        let inputFile = queue.first!.audioFile

        // Setup the engine:

        // 1. attach the player
        engine.attach(playerNode)

        // 2. connect the player to the mixer (we need at least 1 access, even in read mode, to the mainMixerNode, otherwise the start will throw)
        engine.connect(playerNode, to: engine.mainMixerNode, format: inputFile.processingFormat)

        engine.prepare()
        do {
            try engine.start()
        } catch {
            print("error: \(error.localizedDescription)")
        }

        playerNode.scheduleFile(inputFile, at: nil)

        playerNode.play()
    }

    // Pause but remain ready to play
    public func pause() {
        playerNode.pause()
        engine.pause()
    }

    public func stop() {
        queue.removeAll()
        playerNode.stop()
        engine.stop()
    }

    // Jump to the 10 second position
    public func seek(second _: TimeInterval, index _: Int?) {}

    // Skip to the next item
    public func seekToNext() {}

    // Skip to the previous item
    public func seekToPrevious() {}

    public func setShuffleModeEnabled() {}

    public func setSpeed(_: Float) {
        // hint:
        // func scheduleFile(
//          _ file: AVAudioFile,
//          at when: AVAudioTime?,
//          completionCallbackType callbackType: AVAudioPlayerNodeCompletionCallbackType,
//          completionHandler: AVAudioPlayerNodeCompletionHandler? = nil
//          )
        // AVAudioTime.init(audioTimeStamp: UnsafePointer<AudioTimeStamp>, sampleRate: Double)
    }

    public func setVolume(_: Float) {}

    public func setLoopMode(_: LoopMode) {}

    public func setClip(start _: TimeInterval? = nil, end _: TimeInterval? = nil) {}

    // Streams (event channels)
    // - playerStateStream
    // - durationStream
    // - positionStream
    // - bufferedPositionStream
    // - sequenceStateStream
    // - sequenceStream
    // - currentIndexStream
    // - icyMetadataStream
    // - playingStream
    // - processingStateStream
    // - loopModeStream
    // - shuffleModeEnabledStream
    // - volumeStream
    // - speedStream
    // - playbackEventStream
}
