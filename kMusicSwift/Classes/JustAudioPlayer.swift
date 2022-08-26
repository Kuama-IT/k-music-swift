import Darwin
import SwiftAudioPlayer

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

public class JustAudioPlayer {
    // To be forwarded to the http client, in case we load a track from the internet
    var httpHeaders: [String: String] = [:]

    public init() {}

    /// To be modified in order to handle multiple tracks at once
    func setTrack(_: TrackResource) {}

    func setAudioSource(_: AudioSource) {}

    // Play without waiting for completion
    // Play while waiting for completion
    func play() {}

    // Pause but remain ready to play
    func pause() {}

    func stop() {}

    // Jump to the 10 second position
    func seek(second _: TimeInterval, index _: Int?) {}

    // Skip to the next item
    func seekToNext() {}

    // Skip to the previous item
    func seekToPrevious() {}

    func setShuffleModeEnabled() {}

    func setSpeed(_: Float) {
        // hint:
        // func scheduleFile(
//          _ file: AVAudioFile,
//          at when: AVAudioTime?,
//          completionCallbackType callbackType: AVAudioPlayerNodeCompletionCallbackType,
//          completionHandler: AVAudioPlayerNodeCompletionHandler? = nil
//          )
        // AVAudioTime.init(audioTimeStamp: UnsafePointer<AudioTimeStamp>, sampleRate: Double)
    }

    func setVolume(_: Float) {}

    func setLoopMode(_: LoopMode) {}

    func setClip(start _: TimeInterval? = nil, end _: TimeInterval? = nil) {}

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
