//
// SingleAudioSource.swift
// kMusicSwift
// Created by Kuama Dev Team on 01/09/22
// Using Swift 5.0
// Running on macOS 12.5
//

public protocol SingleAudioSource {
    var playingStatus: AudioSourcePlayingStatus { get }

    func setPlayingStatus(_ nextStatus: AudioSourcePlayingStatus) throws
}
