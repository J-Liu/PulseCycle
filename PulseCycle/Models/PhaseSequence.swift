// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2026 Jia Liu
// Licensed under AGPL-3.0-or-later with an additional permission
// under Section 7. See LICENSE for details.

import Foundation

struct PhaseItem {
    let phase: IntervalPhase
    let duration: Int
    let color: String
    let startSound: String?
    let endSound: String?
    let tickSound: String?
    let warningAtSeconds: Int?  // Play warning sound at remaining seconds
    let warningSound: String?

    static func warmUp(_ profile: WorkoutProfile) -> PhaseItem {
        return PhaseItem(
            phase: .warmUp,
            duration: profile.warmUpSeconds,
            color: profile.warmUpColor,
            startSound: profile.startSoundEnabled ? "boxing-bell-1" : nil,
            endSound: nil,  // No end sound, immediately followed by work phase
            tickSound: nil,
            warningAtSeconds: nil,
            warningSound: nil
        )
    }

    static func work(_ profile: WorkoutProfile) -> PhaseItem {
        return PhaseItem(
            phase: .work,
            duration: profile.workSeconds,
            color: profile.workColor,
            startSound: profile.startSoundEnabled ? "boxing-bell-1" : nil,
            endSound: profile.endSoundEnabled ? "boxing-bell-3" : nil,
            tickSound: nil,
            warningAtSeconds: profile.workSeconds >= 15 ? 10 : nil,
            warningSound: profile.endingNotifySoundEnabled ? "boxing-bell-2" : nil
        )
    }

    static func rest(_ profile: WorkoutProfile) -> PhaseItem {
        return PhaseItem(
            phase: .rest,
            duration: profile.restSeconds,
            color: profile.restColor,
            startSound: nil,  // No start sound for rest phase
            endSound: nil,    // No end sound for rest phase
            tickSound: nil,
            warningAtSeconds: nil,  // No warning sound for rest phase
            warningSound: nil
        )
    }

    static func coolDown(_ profile: WorkoutProfile) -> PhaseItem {
        return PhaseItem(
            phase: .coolDown,
            duration: profile.coolDownSeconds,
            color: profile.coolDownColor,
            startSound: nil,  // No start sound, immediately follows work phase
            endSound: profile.endSoundEnabled ? "boxing-bell-3" : nil,
            tickSound: nil,
            warningAtSeconds: profile.coolDownSeconds >= 15 && profile.endingNotifySoundEnabled ? 10 : nil,
            warningSound: profile.endingNotifySoundEnabled ? "boxing-bell-2" : nil
        )
    }
}

class PhaseSequenceBuilder {
    static func build(from profile: WorkoutProfile) -> [PhaseItem] {
        var items: [PhaseItem] = []

        // Warm-up
        if profile.warmUpEnabled {
            items.append(.warmUp(profile))
        }

        // Work/Rest rounds
        for i in 0..<profile.rounds {
            items.append(.work(profile))

            // Add rest after each work except the last one
            // Last work is followed by cool-down (if enabled) or ends the workout
            if i < profile.rounds - 1 {
                items.append(.rest(profile))
            }
        }

        // Cool-down
        if profile.coolDownEnabled {
            items.append(.coolDown(profile))
        }

        return items
    }
}
