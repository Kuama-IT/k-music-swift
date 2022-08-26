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
    private let engine: AVAudioEngine = .init()
    private let playerNode: AVAudioPlayerNode = .init()
    // To be forwarded to the http client, in case we load a track from the internet
    var httpHeaders: [String: String] = [:]

    public init() {}

    /// To be modified in order to handle multiple tracks at once
    public func setTrack(_: TrackResource) {}

    public func setAudioSource(_: AudioSource) {}

    // Play without waiting for completion
    // Play while waiting for completion
    public func play(trackPath: String) {
        // Read track URL from the bundle assets
        guard let inputFileUrl = Bundle.main.url(forResource: trackPath, withExtension: "mp3") else {
            fatalError("could not load a track")
        }
        // Load the track inside a AVAudioFile
        guard let inputFile = try? AVAudioFile(forReading: inputFileUrl) else {
            fatalError("input file fail")
        }

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

        // Prepare the output file
        guard let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("document directory fail")
        }

        let outputFileUrl = documentsDirectoryURL.appendingPathComponent(Date.now.ISO8601Format())

        // Handy while testing to retrieve quickly the file inside the OS filesystem
        print(outputFileUrl.absoluteString)

        // We need some settings for the output audio file. The quickiest way to test this is to grab the same settings of the output node of the engine.
        // Sadly it defaults to WAV format for the output file, and since we're planning to upload this file to the server, is the less performant format
        // Some work should be done to extrapolate a good settings configuration (see final comment)
        let settings = engine.outputNode.outputFormat(forBus: 0).settings

        guard let outputFile = try? AVAudioFile(forWriting: outputFileUrl, settings: settings) else {
            fatalError("document directory fail")
        }

        // Write engine final output to file:
        // outputNode will never trigget the tap 🤷‍♂️ (probably because we didn't connect anything), but since we can connect player -> effects -> mainMixerNode
        // tapping the last node is more than enough for a poc 🥷.
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { buffer, _ in
            do {
                try outputFile.write(from: buffer)
            } catch {
                // We cannot re-throw here due to the signature of the block
                print("Error: \(error)")
                print("Description: \(error.localizedDescription)")
            }
        }

        playerNode.play()
    }

    // Pause but remain ready to play
    public func pause() {
        playerNode.pause()
        engine.pause() 
        
    }

    public func stop() {
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
