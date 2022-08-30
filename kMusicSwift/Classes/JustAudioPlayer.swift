import AVFoundation
import Combine
import Darwin
import Foundation
import SwiftAudioPlayer

// Icy Metadata (?)
// Volume ✅✅
// Composite state (?)
// Loop modes ✅✅
// Request headers ✅✅
// Concatenating ✅
// Gapless transitions ✅
// HLS (?)
// Radio/Livestreams ✅✅
// Time stretching (1x, 2x) ✅
// Buffer position (on download from http) ✅✅
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
    // whether we're currently playing a song
    @Published public private(set) var isPlaying: Bool = false

    // the current loop mode
    @Published public private(set) var loopMode: LoopMode = .off

    // player node volume value
    @Published public private(set) var volume: Float?

    // buffer duration
    @Published public private(set) var bufferPosition: Double?

    // forwarded to the SAPlayer http client, in case we load a track from the internet and need to set some headers
    var httpHeaders: [String: String] = [:] {
        didSet {
            SAPlayer.shared.HTTPHeaderFields = httpHeaders
        }
    }

    /// Tracks which track is being reproduced
    private var queueIndex: Int?

    /// Full list of tracks that will be played
    private var queue: [TrackResource] = []

    /// Track that is currently being processed
    private var currentTrack: TrackResource? {
        if let index = queueIndex {
            return queue[index]
        }

        return nil
    }

    // Notification subscriptions
    private var playingStatusSubscription: UInt?
    private var streamingBufferSubscription: UInt?

    public init() {
        subscribeToPlayingStatusUpdates()
        subscribeToBufferPosition()
    }

    /// To be modified in order to handle multiple tracks at once
    public func addTrack(_ track: TrackResource) {
        queue.append(track)
    }

    public func setAudioSource(_: AudioSource) {}

    /// Starts to play the current queue of the player
    /// If the player is already playing, calling this method will result in a no-op
    public func play() {
        guard let node = SAPlayer.shared.playerNode else {
            // first time to play a song
            if let track = tryMoveToNextTrack() {
                play(track: track)
            }
            return
        }
        if node.isPlaying {
            return
        } else {
            // player node is in pause
            SAPlayer.shared.play()
        }
    }

    // Pause but remain ready to play
    public func pause() {
        SAPlayer.shared.pause()
    }

    public func stop() {
        SAPlayer.shared.stopStreamingRemoteAudio()
        SAPlayer.shared.playerNode?.stop()
        SAPlayer.shared.engine?.stop()
        queue.removeAll()
        unsubscribeUpdates()
    }

    // TODO: Jump to the 10 second position
    public func seek(second _: TimeInterval, index _: Int?) {}

    // Skip to the next item
    public func seekToNext() {
        if let track = tryMoveToNextTrack(isForced: true) {
            play(track: track)
        }
    }

    // TODO: Skip to the previous item
    public func seekToPrevious() {}

    // TODO:
    public func setShuffleModeEnabled() {}

    // TODO:
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
        SAPlayer.shared.playerNode?.volume = volume
    }

    // Set the loop mode
    public func setLoopMode(_ loopMode: LoopMode) {
        self.loopMode = loopMode
    }

    // set the next loop mode
    public func setNextLoopMode() {
        switch loopMode {
        case .off:
            loopMode = .one
        case .one:
            loopMode = .all
        case .all:
            loopMode = .off
        }
    }

    // TODO:
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

    /**
     * Tries to move the queue index to the next track.
     * If we're on the last track of the queue or the queue is empty, the queueIndex will not change.
     * `LoopMode.one` works only when a track finishes by itself.
     * - Parameter isForced: whether the next song must be played (ex. seek to next)
     */
    func tryMoveToNextTrack(isForced: Bool = false) -> TrackResource? {
        let currentIndex = queueIndex ?? 0

        if !isForced {
            // do not change the index, and return the current track
            if loopMode == LoopMode.one {
                queueIndex = currentIndex
                return queue[currentIndex]
            }
        }
        let nextIndex = queueIndex != nil ? currentIndex + 1 : currentIndex

        // simply, the next track available
        if queue.indices.contains(nextIndex) {
            queueIndex = nextIndex
            return queue[nextIndex]
        }

        // stop the player when we're at the end of the queue and is not forced the seek
        if loopMode == .off && !isForced {
            queueIndex = nil
            return nil
        }

        // we're at the end of the queue, automatically go back to the first element
        if loopMode == .all || isForced {
            queueIndex = 0
            return queue[0]
        }

        // undetermined case, should never happens
        return nil
    }

    func play(track trackResource: TrackResource) {
        if let url = trackResource.audioUrl {
            if trackResource.isRemote {
                SAPlayer.shared.startRemoteAudio(withRemoteUrl: url)
            } else {
                SAPlayer.shared.startSavedAudio(withSavedUrl: url)
            }

            SAPlayer.shared.play()
        }
    }
}

// MARK: - SwiftAudioPlayer private subscriptions

@available(iOS 15.0, *)
private extension JustAudioPlayer {
    func subscribeToPlayingStatusUpdates() {
        playingStatusSubscription = SAPlayer.Updates.PlayingStatus
            .subscribe { [weak self] playingStatus in

                // Edge case:
                // When playing a remote song, we often receive this sequence of statuses:
                //
                // buffering
                // ended
                // playing
                //
                // or worse:
                //
                // ended
                // buffering
                // playing
                // To avoid going to the next song in these situations, we need to know if the current track is really playing

                // TODO: remove when stable
                print(playingStatus)

                let convertedTrackStatus: TrackResourcePlayingStatus = TrackResourcePlayingStatus.fromSAPlayingStatus(playingStatus)

                self?.currentTrack?.setPlayingStatus(convertedTrackStatus)

                let currentTrackPlayingStatus = self?.currentTrack?.playingStatus ?? .idle

                print("current: \(currentTrackPlayingStatus)")

                if currentTrackPlayingStatus == .ended {
                    if let track = self?.tryMoveToNextTrack() {
                        self?.play(track: track)
                    }
                }

                // propagate status to subscribers
                self?.isPlaying = currentTrackPlayingStatus == .playing
            }
    }

    func subscribeToBufferPosition() {
        streamingBufferSubscription = SAPlayer.Updates.StreamingBuffer
            .subscribe { [weak self] buffer in
                // TODO: once we hook to the UI verify this is the correct value to proxy
                self?.bufferPosition = buffer.totalDurationBuffered
            }
    }

    func unsubscribeUpdates() {
        if let subscription = playingStatusSubscription {
            SAPlayer.Updates.PlayingStatus.unsubscribe(subscription)
        }

        if let subscription = streamingBufferSubscription {
            SAPlayer.Updates.StreamingBuffer.unsubscribe(subscription)
        }
    }
}
