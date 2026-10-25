// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2026 Jia Liu
// Licensed under AGPL-3.0-or-later with an additional permission
// under Section 7. See LICENSE for details.

import AVFoundation

class SoundManager {
    static let shared = SoundManager()

    private var audioPlayers: [String: AVAudioPlayer] = [:]

    // Available sounds
    static let availableSounds = [
        "boxing-bell-1",
        "boxing-bell-2",
        "boxing-bell-3",
        "countdown_beep"
    ]

    private init() {
        preloadSounds()
    }

    private func preloadSounds() {
        for soundName in SoundManager.availableSounds {
            if let url = Bundle.main.url(forResource: soundName, withExtension: "wav") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    audioPlayers[soundName] = player
                } catch {
                    print("Failed to load sound: \(soundName)")
                }
            }
        }
    }

    func playSound(_ soundName: String) {
        guard let player = audioPlayers[soundName] else {
            print("Sound not found: \(soundName)")
            return
        }

        player.currentTime = 0
        player.play()
    }

    func playStartSound() {
        playSound("boxing-bell-1")
    }

    func playEndSound() {
        playSound("boxing-bell-3")
    }

    func playWarningSound() {
        playSound("countdown_beep")
    }
}
