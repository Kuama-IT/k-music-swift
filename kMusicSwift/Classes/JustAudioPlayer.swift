import AVFoundation
import Combine
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

    public private(set) var loopMode: LoopMode = .off

    private let engine: AVAudioEngine = .init()
    private let playerNode: AVAudioPlayerNode = .init()

    // To be forwarded to the http client, in case we load a track from the internet
    var httpHeaders: [String: String] = [:]

    /// Tracks which track is being reproduced
    private var queueIndex: Int?
    private var queue: [TrackResource] = []

    // player node volume value
    @Published public private(set) var volume: Float?

    public init() {}

    /// To be modified in order to handle multiple tracks at once
    public func addTrack(_ track: TrackResource) {
        queue.append(track)
    }

    public func setAudioSource(_: AudioSource) {}

    /// Starts to play the current queue of the player
    /// If the player is already playing, calling this method will result in a no-op
    public func play() throws {
        if isPlaying {
            return
        }

        if let track = getNextTrack() {
            try setupEngine(withProcessingFormat: track.processingFormat)

            playNext(track: track)
        }
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

    // set the node volume
    // N.B. it is the player node volume value, not the device's one
    public func setVolume(_ volume: Float) throws {
        guard volume >= 0.0 || volume <= 1.0 else {
            throw VolumeValueNotValid(value: volume)
        }
        self.volume = volume
        playerNode.volume = volume
    }

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

    // MARK: - Queue

    func getNextTrack() -> AVAudioFile? {
        // side effect
        let currentIndex = queueIndex ?? 0

        if loopMode == LoopMode.one {
            return queue[currentIndex].audioFile
        }

        let nextIndex = queueIndex != nil ? currentIndex + 1 : currentIndex

        if queue.indices.contains(nextIndex) {
            queueIndex = nextIndex
            return queue[nextIndex].audioFile
        }

        if loopMode == .all {
            queueIndex = 0
            return queue[0].audioFile
        }

        return nil
    }

    func playNext(track audioFile: AVAudioFile) {
        playerNode.scheduleFile(audioFile, at: nil) {
            // check and see if we have any other tracks to play
            if let track = self.getNextTrack() {
                self.playNext(track: track)
            }
        }

        playerNode.play()
    }

    // MARK: - Engine

    // TODO: evaluate possible extrapolation to own engine class
    // TODO: manage consecutive calls to this method: we should either have a state to decide what to do or expect to be in a "clean" state
    private func setupEngine(withProcessingFormat processingFormat: AVAudioFormat) throws {
        // Setup the engine:

        // 1. attach the player
        engine.attach(playerNode)

        // 2. connect the player to the mixer (we need at least 1 access, even in read mode, to the mainMixerNode, otherwise the start will throw)
        engine.connect(playerNode, to: engine.mainMixerNode, format: processingFormat)

        engine.prepare()

        do {
            try engine.start()
        } catch {
            throw CouldNotStartEngineError(message: "Could not start the engine, check the cause for the full error", cause: error)
        }
    }
}
