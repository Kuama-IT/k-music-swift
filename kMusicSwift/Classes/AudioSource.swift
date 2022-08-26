//
//  AudioSource.swift
//  kMusicSwift
//
//  Created by Mac on 26/08/22.
//
public class AudioSource {}
// Byte streams
public class StreamAudioSource: AudioSource {}
public class DashAudioSource: AudioSource {}
public class HlsAudioSource: AudioSource {}
public class ProgressiveAudioSource: AudioSource {}
// This is the playlist
public class ConcatenatingAudioSource: AudioSource {
    func add(_: AudioSource) {}
    func insert(at _: Int, _: AudioSource) {}
    func remove(at _: Int) {}
}

public class ClippingAudioSource: AudioSource {}
