# Main Features
- [ ] Icy Metadata (?)
- [x] Volume
- [x] Loop modes
- [x] Request headers
- [x] Concatenating 
- [ ] HLS (?)
- [x] Radio/Livestreams
- [x] Time stretching (1x, 2x)
- [x] Buffer position (on download from http)
- [x] Shuffling
- [x] Clipping
- [x] Playlist editing

# Audio effects
- [ ] Multiple tracks in one time
- [x] Audio effects on a per-track basis
- [x] Mixer
- [x] Mixer presets
- [x] Mixed output to file (or stream?)

# Streams (event channels)
- [ ] icyMetadataStream (?) 
- [ ] playerStateStream (combine playingStream and processingState stream)
- [ ] sequenceStateStream (combine queue, currentIndexStream, shuffledIndexStream, shuffleModeEnabledStream and loopModeStream)
- [ ] sequenceStream (queue)
- [ ] playbackEventStream (combine processingStateStream, updateTime, updatePosition, bufferedPosition, duration,
                            icyMetadata, currentIndex, androidAudioSessionId (ios???) streams)
- [x] durationStream
- [x] positionStream
- [x] bufferedPositionStream
- [x] currentIndexStream
- [x] playingStream
- [x] processingStateStream
- [x] loopModeStream
- [x] shuffleModeEnabledStream
- [x] volumeStream
- [x] speedStream
