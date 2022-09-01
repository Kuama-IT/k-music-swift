import AVFoundation
import Combine
import Darwin
import Foundation
import SwiftAudioPlayer

public enum LoopMode {
    case off
    case one
    case all
}

/// Enumerates the different processing states of a player.
public enum ProcessingState {
    case none
    case loading
    case buffering
    case ready
    case completed
}

@available(iOS 15.0, *)
public class JustAudioPlayer {
    /**
     Represents the time that must elapse before choose to restart a song or seek to the previous one.
     Expressed in seconds
     */
    private static let ELAPSED_TIME_TO_RESTART_A_SONG = 5.0

    // MARK: - Event Streams

    // whether we're currently playing a song
    @Published public private(set) var isPlaying: Bool = false

    // the current loop mode
    @Published public private(set) var loopMode: LoopMode = .off

    // player node volume value
    @Published public private(set) var volume: Float?

    // buffer duration
    @Published public private(set) var bufferPosition: Double?

    // track duration
    @Published public private(set) var duration: Double?

    // processing state
    @Published public private(set) var processingState: ProcessingState = .none

    // elapsed time
    @Published public private(set) var elapsedTime: Double?

    // Tracks which track is being reproduced (currentIndexStream)
    @Published public private(set) var queueIndex: Int?

    // MARK: - Http headers

    /**
     Allows to set the http headers of the request that the player internally does to retrieve a stream or a single audio.
     These headers are unique for player, and will be shared for all of the queued `AudioSource`
     */
    var httpHeaders: [String: String] = [:] {
        didSet {
            SAPlayer.shared.HTTPHeaderFields = httpHeaders
        }
    }

    // MARK: - Internal state

    /// Full list of tracks that will be played
    private var queue: [TrackResource] = []

    /// Track that is currently being processed
    private var currentTrack: TrackResource? {
        if let index = queueIndex {
            return queue[index]
        }

        return nil
    }

    // MARK: - Notification subscriptions

    private var playingStatusSubscription: UInt?
    private var elapsedTimeSubscription: UInt?
    private var durationSubscription: UInt?
    private var streamingBufferSubscription: UInt?

    // MARK: - Constructor

    public init() {
        subscribeToAllSubscriptions()
    }

    // MARK: - Public API

    /// To be modified in order to handle multiple tracks at once
    public func addTrack(_ track: TrackResource) {
        queue.append(track)
    }

    public func setAudioSource(_: AudioSource) {}

    /**
     Starts to play the current queue of the player
     If the player is already playing, calling this method will result in a no-op
     */
    public func play() {
        guard let node = SAPlayer.shared.playerNode else {
            // first time to play a song
            if let track = tryMoveToNextTrack() {
                processingState = .loading
                play(track: track)
            } else {
                processingState = .completed
            }
            return
        }

        if node.isPlaying {
            return
        } else {
            // player node is in pause
            processingState = .loading
            SAPlayer.shared.play()
        }
    }

    /**
     Pause the player, but keeps it ready to play (`queue` will not be dropped, `queueIndex` will not change)
     */
    public func pause() {
        processingState = .ready
        SAPlayer.shared.pause()
    }

    /**
     Stops the player, looses the queue and the current index
     */
    public func stop() {
        processingState = .none
        SAPlayer.shared.stopStreamingRemoteAudio()
        SAPlayer.shared.playerNode?.stop()
        SAPlayer.shared.engine?.stop()
        queue.removeAll()
        queueIndex = 0
        unsubscribeUpdates()
    }

    /// seek to a determinate value, default is 10 second forward
    public func seek(second: Double = 10.0) {
        SAPlayer.shared.seekTo(seconds: second)
    }

    /// Skip to the next item
    public func seekToNext() {
        if let track = tryMoveToNextTrack(isForced: true) {
            play(track: track)
        }
    }

    /// Skip to the previous item
    public func seekToPrevious() {
        play(track: tryMoveToPreviousTrack())
    }

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

    /**
     Sets the node volume
     N.B. it is the player node volume value, not the device's one
     */
    public func setVolume(_ volume: Float) throws {
        guard volume >= 0.0 || volume <= 1.0 else {
            throw VolumeValueNotValid(value: volume)
        }
        self.volume = volume
        SAPlayer.shared.playerNode?.volume = volume
    }

    /**
     Sets the player loop mode.
     Warning: if one of the `AudioSources` in queue is a `LoopingAudioSource`, its "loop" will override the player loop
     */
    public func setLoopMode(_ loopMode: LoopMode) {
        self.loopMode = loopMode
    }

    /**
     Sets the next loop mode. Allow the user to keep touching the same button to toggle between the different `LoopMode`s
     */
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

    // MARK: - Private API

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

    /*
     * Always try to push back the player
     * no edge cases
     */
    func tryMoveToPreviousTrack() -> TrackResource {
        guard queue.count > 1 else {
            preconditionFailure("no track has been set")
        }
        let currentIndex = queueIndex ?? 0
        // if track is playing for more than 5 second, restart the current track
        if SAPlayer.shared.elapsedTime ?? 0 >= JustAudioPlayer.ELAPSED_TIME_TO_RESTART_A_SONG {
            queueIndex = currentIndex
            return queue[currentIndex]
        }

        let previousIndex = currentIndex - 1

        if previousIndex == -1 {
            // first song and want to go back to end of the queue
            queueIndex = queue.count - 1
            return queue[queueIndex!]
        }

        if queue.indices.contains(previousIndex) {
            queueIndex = previousIndex
            return queue[previousIndex]
        }

        queueIndex = previousIndex
        return queue[previousIndex]
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
    func subscribeToAllSubscriptions() {
        subscribeToPlayingStatusUpdates()
        subscribeToBufferPosition()
        subscribeToElapsedTime()
        subscribeToDuration()
    }

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

                let convertedTrackStatus: AudioSourcePlayingStatus = AudioSourcePlayingStatus.fromSAPlayingStatus(playingStatus)

                self?.currentTrack?.setPlayingStatus(convertedTrackStatus)

                let currentTrackPlayingStatus = self?.currentTrack?.playingStatus ?? .idle

                print("current: \(currentTrackPlayingStatus)")
                if currentTrackPlayingStatus == .buffering {
                    self?.processingState = .buffering
                }

                if currentTrackPlayingStatus == .ended {
                    if let track = self?.tryMoveToNextTrack() {
                        self?.play(track: track)
                    }
                } else {
                    self?.processingState = .completed
                }

                // propagate status to subscribers
                self?.isPlaying = currentTrackPlayingStatus == .playing

                // As seen on Android
                if self?.isPlaying == true {
                    self?.processingState = .ready
                }
            }
    }

    func subscribeToBufferPosition() {
        streamingBufferSubscription = SAPlayer.Updates.StreamingBuffer
            .subscribe { [weak self] buffer in
                // TODO: once we hook to the UI verify this is the correct value to proxy
                self?.bufferPosition = buffer.bufferingProgress
            }
    }

    func subscribeToElapsedTime() {
        streamingBufferSubscription = SAPlayer.Updates.ElapsedTime
            .subscribe { [weak self] elapsedTime in
                self?.elapsedTime = elapsedTime
            }
    }

    func subscribeToDuration() {
        durationSubscription = SAPlayer.Updates.Duration
            .subscribe { [weak self] duration in
                self?.duration = duration
            }
    }

    func unsubscribeUpdates() {
        if let subscription = elapsedTimeSubscription {
            SAPlayer.Updates.ElapsedTime.unsubscribe(subscription)
        }
        if let subscription = durationSubscription {
            SAPlayer.Updates.ElapsedTime.unsubscribe(subscription)
        }
        if let subscription = playingStatusSubscription {
            SAPlayer.Updates.PlayingStatus.unsubscribe(subscription)
        }

        if let subscription = streamingBufferSubscription {
            SAPlayer.Updates.StreamingBuffer.unsubscribe(subscription)
        }
    }
}
