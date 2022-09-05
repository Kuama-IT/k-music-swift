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

    // Whether the tracks in the queue are played in shuffled order
    public var isShuffling: Published<Bool>.Publisher {
        queueManager.$shouldShuffle
    }

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

    private var queueManager = AudioSequenceQueueManager()

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

    public func addAudioSource(_ sequence: AudioSequence) {
        queueManager.addAll(sources: [sequence])
    }

    public func removeAudioSource(at index: Int) throws {
        try queueManager.remove(at: index)
    }

    /**
     Starts to play the current queue of the player
     If the player is already playing, calling this method will result in a no-op
     */
    public func play() throws {
        guard let node = SAPlayer.shared.playerNode else {
            // first time to play a song
            if let track = try tryMoveToNextTrack() {
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
        queueManager.clear()
        queueIndex = 0
        unsubscribeUpdates()
    }

    /// seek to a determinate value, default is 10 second forward
    public func seek(second: Double = 10.0) {
        SAPlayer.shared.seekTo(seconds: second)
    }

    /// Skip to the next item
    public func seekToNext() throws {
        if let track = try tryMoveToNextTrack(isForced: true) {
            play(track: track)
        }
    }

    /// Skip to the previous item
    public func seekToPrevious() throws {
        play(track: try tryMoveToPreviousTrack())
    }

    /// Toggles shuffle mode
    public func setShuffleModeEnabled(_ shouldShuffle: Bool) {
        queueManager.shouldShuffle = shouldShuffle
    }

    /// Sets a shuffle playback order for a specific `AudioSequence` in the queue
    public func shuffle(at index: Int, inOrder newOrder: [Int]) throws {
        try queueManager.shuffle(at: index, inOrder: newOrder)
    }

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
            throw VolumeValueNotValidError(value: volume)
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
    func tryMoveToNextTrack(isForced: Bool = false) throws -> AudioSource? {
        let currentIndex = queueIndex ?? 0

        if !isForced {
            // do not change the index, and return the current track
            if loopMode == LoopMode.one {
                queueIndex = currentIndex
                return try queueManager.element(at: currentIndex)
            }
        }
        let nextIndex = queueIndex != nil ? currentIndex + 1 : currentIndex

        // simply, the next track available
        if queueManager.contains(nextIndex) {
            queueIndex = nextIndex
            return try queueManager.element(at: nextIndex)
        }

        // stop the player when we're at the end of the queue and is not forced the seek
        if loopMode == .off && !isForced {
            queueIndex = nil
            return nil
        }

        // we're at the end of the queue, automatically go back to the first element
        if loopMode == .all || isForced {
            queueIndex = 0
            return queueManager.first
        }

        // undetermined case, should never happens
        return nil
    }

    /*
     * Always try to push back the player
     * no edge cases
     */
    func tryMoveToPreviousTrack() throws -> AudioSource {
        guard queueManager.count > 1 else {
            preconditionFailure("no track has been set")
        }
        let currentIndex = queueIndex ?? 0
        // if track is playing for more than 5 second, restart the current track
        if SAPlayer.shared.elapsedTime ?? 0 >= JustAudioPlayer.ELAPSED_TIME_TO_RESTART_A_SONG {
            queueIndex = currentIndex
            return try queueManager.element(at: currentIndex)
        }

        let previousIndex = currentIndex - 1

        if previousIndex == -1 {
            // first song and want to go back to end of the queue
            queueIndex = queueManager.count - 1
            return try queueManager.element(at: queueIndex!)
        }

        if queueManager.contains(previousIndex) {
            queueIndex = previousIndex
            return try queueManager.element(at: previousIndex)
        }

        queueIndex = previousIndex
        return try queueManager.element(at: previousIndex)
    }

    func play(track audioSource: AudioSource) {
        
        var realAudioSource = audioSource
        
        if let clippingAudioSource = audioSource as? ClippingAudioSource {
            realAudioSource = clippingAudioSource.realAudioSource
        }
        
        if let url = audioSource.audioUrl {
            switch realAudioSource {
            case is LocalAudioSource:
                SAPlayer.shared.startSavedAudio(withSavedUrl: url)
            case is RemoteAudioSource:
                SAPlayer.shared.startRemoteAudio(withRemoteUrl: url)
            default:
                // TODO: should we throw?
                preconditionFailure("Don't know how to play \(audioSource.self)")
            }

            

            if let audioSource = audioSource as? ClippingAudioSource {
                processingState = .loading
                SAPlayer.shared.seekTo(seconds: Double(audioSource.start))
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

                guard let self = self, let queueIndex = self.queueIndex else {
                    return
                }

                if self.volume == nil {
                    self.volume = SAPlayer.shared.playerNode?.volume
                }

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
                
                do {
                    let convertedTrackStatus = AudioSourcePlayingStatus.fromSAPlayingStatus(playingStatus)

                    let audioSource = try self.queueManager.element(at: queueIndex)
//                    if(convertedTrackStatus == .paused && self.processingState == .loading && audioSource.playingStatus == .buffering) {
//                        // SAPlayer sometimes, on remote songs, after we force a skip, puts itself into pause. We do not want this behaviour
//                        SAPlayer.shared.play()
//                        return
//                    }
                    
                    try audioSource.setPlayingStatus(convertedTrackStatus)

                    let currentTrackPlayingStatus = audioSource.playingStatus

                    print("current: \(currentTrackPlayingStatus)")

                    if currentTrackPlayingStatus == .buffering {
                        self.processingState = .buffering
                    }

                    if currentTrackPlayingStatus == .ended {
                        if let track = try self.tryMoveToNextTrack() {
                            self.play(track: track)
                        }
                    } else {
                        self.processingState = .completed
                    }

                    // propagate status to subscribers
                    self.isPlaying = currentTrackPlayingStatus == .playing

                    // As seen on Android
                    if self.isPlaying == true {
                        self.processingState = .ready
                    }
                } catch {
                    print("Unexpected error \(error)")
                    self.processingState = .none
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
            .subscribe { [weak self] elapsedTime in // let's assume this is expressed in seconds
                self?.elapsedTime = elapsedTime
                do {
                    guard let currentIndex = self?.queueIndex else {
                        return
                    }

                    if let audioSource = try self?.queueManager.element(at: currentIndex) as? ClippingAudioSource {
                        if elapsedTime >= Double(audioSource.end) {
                            try audioSource.setPlayingStatus(.ended)
                            if let track = try self?.tryMoveToNextTrack() {
                                self?.play(track: track)
                            } else {
                                self?.processingState = .completed
                                self?.stop()
                            }
                        }
                    }
                } catch {
                    print("Unexpected error \(error)")
                }
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
